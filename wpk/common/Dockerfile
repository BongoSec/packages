FROM debian:9
RUN echo "deb http://archive.debian.org/debian stretch contrib main non-free" > /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian-security stretch/updates main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get -y install --allow-change-held-packages python git curl jq python3 python3-pip libffi-dev && \
    pip3 install --upgrade cryptography==2.9.2 awscli

ADD wpkpack.py /usr/local/bin/wpkpack
ADD run.sh /usr/local/bin/run
VOLUME /var/local/bongosec
VOLUME /etc/bongosec
VOLUME /etc/bongosec/checksum
ENTRYPOINT ["/usr/local/bin/run"]
