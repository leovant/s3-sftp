FROM debian:9

RUN apt-get -y update && apt-get -y install --no-install-recommends \
    automake \
    autotools-dev \
    g++ \
    libcurl4-gnutls-dev \
    libfuse-dev \
    libssl-dev \
    libxml2-dev \
    make \
    pkg-config \
    python3-pip \
    vsftpd \
    openssh-server \
    supervisor \
    s3fs

RUN touch ~/.passwd-s3fs && chmod 600 ~/.passwd-s3fs && mkdir /ftp /scripts

ADD start-s3fs.sh /scripts/start-s3fs.sh
ADD vsftpd.conf /etc/vsftpd.conf
ADD sshd_config /etc/ssh/sshd_config
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN chown root:root /etc/vsftpd.conf
RUN chmod +x /scripts/start-s3fs.sh

EXPOSE 21 22

CMD [ "/usr/bin/supervisord" ]
