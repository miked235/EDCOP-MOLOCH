#!/bin/bash
# Script to initialize Moloch, add a user, and run the services

# Copy configmap for editing
if [ -f /tmp/moloch/config.ini ]; then
  yes | cp /tmp/moloch/config.ini /data/moloch/etc/config.ini
fi

# Insert interface environment variable into config
sed -i 's/${INTERFACE}/'$INTERFACE' /g' /data/moloch/etc/config.ini
sed -i 's/${POD_NAME}/'$POD_NAME' /g' /data/moloch/etc/config.ini

# Check to see if Elasticsearch is reachable
echo "Trying to reach Elasticsearch..."
until $(curl --output /dev/null --fail --silent -X GET "$ES_HOST:9200/_cat/health?v"); do
  echo "Couldn't get Elasticsearch at $ES_HOST:9200, are you sure it's reachable?"
  sleep 5
done

# Check to see if Moloch has been installed before to prevent data loss
STATUS5=$(curl -s -X GET "$ES_HOST:9200/sequence_v1" | jq --raw-output '.status')
STATUS6=$(curl -s -X GET "$ES_HOST:9200/sequence_v2" | jq --raw-output '.status')

# Initialize Moloch if this is the first install
if [ "$STATUS5" = "404" ] && [ "$STATUS6" = "404" ]
then
  echo "First time install, initializing Moloch indices..."
  echo INIT | /data/moloch/db/db.pl http://$ES_HOST:9200 init
  /data/moloch/bin/moloch_add_user.sh admin "Admin User" $ADMIN_PW --admin
else
  echo "Moloch has already been initialized, skipping index initialization..."
fi

# Deploy Moloch as a sensor node
if [ "$SENSOR" = "true" ]
then
  echo "Capture node selected, configuring interface..."
  /sbin/ethtool -G $INTERFACE rx 4096 tx 4096 || true
  for i in rx tx sg tso ufo gso gro lro; do
    /sbin/ethtool -K $INTERFACE $i off || true
  done
  echo "Starting Moloch capture and viewer..."
  cd /data/moloch
  nohup /data/moloch/bin/moloch-capture -c /data/moloch/etc/config.ini >> /data/moloch/logs/capture.log 2>&1 &
  cd /data/moloch/viewer
  /data/moloch/bin/node viewer.js -c /data/moloch/etc/config.ini >> /data/moloch/logs/viewer.log 2>&1
# Viewer only node
else
  echo "Viewer node selected, starting Moloch viewer..."
  cd /data/moloch/viewer
  /data/moloch/bin/node viewer.js -c /data/moloch/etc/config.ini >> /data/moloch/logs/viewer.log 2>&1
fi
