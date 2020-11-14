FROM debian:stretch-slim
MAINTAINER postarc <postarc@nm.ru>

ARG CONTAINER_TIMEZONE=Europe/Moscow
ARG VERSION=0.23.1

ENV PATH=/opt/particl-${PARTICL_VERSION}/bin:$PATH

# TODO: cleanup
RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y apt-transport-https ca-certificates wget curl gnupg2 autogen git net-tools iputils-ping ntp ntpdate \
#    build-essential libtool autotools-dev automake autoconf pkg-config libssl-dev libboost-all-dev  \
#    libzmq3-dev libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler \
#    libqrencode-dev autoconf openssl libevent-dev libminiupnpc-dev bsdmainutils libsodium-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo ${CONTAINER_TIMEZONE} >/etc/timezone && \
    ln -sf /usr/share/zoneinfo/${CONTAINER_TIMEZONE} /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    echo "Container timezone set to: $CONTAINER_TIMEZONE"

RUN ntpdate -q ntp.ubuntu.com

RUN cd /root \
        && mkdir -p idena \
        && cd idena \
        && wget https://github.com/idena-network/idena-go/releases/download/v${VERSION}/idena-node-linux-${VERSION} \
        && cp -rf idena-node-linux-${VERSION} idena-go;

RUN mkdir /root/.idena/
VOLUME ["/root/.idena/"]

RUN mkdir -p /opt/idena/bin \
    && cp -rf /root/idena/idena-go /opt/idena/bin/ \
    && rm -rf /root/idena

COPY config.json /root/.idena/config.json
COPY docker-entrypoint.sh /opt/idena/bin/entrypoint.sh 

ENV PATH="/opt/idena/bin:${PATH}"
RUN chmod +x /opt/idena/bin/*

#EXPOSE 40403 40404 9009

#ENTRYPOINT ["docker-entrypoint.sh"]
#CMD ["idena-go"]
#
