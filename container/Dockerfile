FROM centos:latest
ENV VERSION=1.6.2 \
  ES_HOST=elasticsearch \
  INTERFACE=eth1 \
  CLUSTER_PW=secretpw \
  ADMIN_PW=supersecretpw \
  SENSOR=true

RUN yum -y update && yum -y install epel-release && \
	yum -y install jq wget nodejs bzip2 curl net-tools fontconfig freetype freetype-devel fontconfig-devel libyaml-devel libpcap-devel libstdc++ ethtool pcre tcpdump pcre-devel libyaml pkgconfig flex bison gcc-c++ zlib-devel e2fsprogs-devel openssl-devel file-devel make gettext libuuid-devel perl-JSON bzip2-libs bzip2-devel perl-libwww-perl libpng-devel xz libffi-devel GeoIP vim && \
	wget https://files.molo.ch/builds/centos-7/moloch-$VERSION-1.x86_64.rpm && \
	rpm -i moloch-$VERSION-1.x86_64.rpm && \
	adduser --system --no-create-home --user-group moloch

ADD scripts /data/moloch/

RUN cd /data/moloch && \
  chmod +x docker-entrypoint.sh config-moloch.sh && \
  ./config-moloch.sh && \
  chmod +x db/db.pl bin/*.sh && \
  setcap 'CAP_NET_RAW+ep CAP_NET_ADMIN+ep CAP_IPC_LOCK+ep' /data/moloch/bin/moloch-capture && \
  ln -s /data/moloch/bin/node /usr/bin/nodejs && \
  cd viewer && \
  npm update . && \
  npm install . && \
  yum clean -y all

ADD etc/config.ini /data/moloch/etc/config.ini

RUN chmod -R 775 /data/moloch/etc && \
  chown -R moloch /data/moloch

EXPOSE 8005
WORKDIR /data/moloch
USER moloch

ENTRYPOINT ["./docker-entrypoint.sh"]
