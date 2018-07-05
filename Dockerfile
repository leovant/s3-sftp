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

ENV FTP_DIRECTORY=/home/ftp/bucket
ENV S3FS_CONF_FILE=/home/ftp/.passwd-s3fs

RUN groupadd ftpaccess
RUN mkdir -p ${FTP_DIRECTORY} && chown root:root ${FTP_DIRECTORY} && chmod 755 ${FTP_DIRECTORY}
RUN touch ${S3FS_CONF_FILE} && chmod 600 ${S3FS_CONF_FILE}

ADD start-s3fs.sh /usr/local/start-s3fs.sh
ADD read-users.sh /usr/local/read-users.sh
ADD vsftpd.conf /etc/vsftpd.conf
ADD sshd_config /etc/ssh/sshd_config
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN chown root:root /etc/vsftpd.conf
RUN chmod +x /usr/local/start-s3fs.sh
RUN chmod +x /usr/local/read-users.sh

RUN mkdir /run/sshd

EXPOSE 21 22

CMD [ "/usr/bin/supervisord" ]
