FROM centos:centos7

MAINTAINER Bin Xiong <bin.xiong@pearson.com>
LABEL Vendor="CentOS"
LABEL License=GPLv2
LABEL Version=5.6.0
ENV container docker

RUN mkdir -p /app 

WORKDIR /app

COPY Percona*.rpm /app/
RUN yum -y install Percona-Server-*.rpm
RUN yum clean all && rm -f /app/*.rpm

COPY my.cnf /etc/
COPY docker-entrypoint.sh /app/

RUN mkdir -p /data/mysql /logs/mysql && chown -R mysql:mysql /data/mysql /logs/mysql
VOLUME ["/data/mysql", "/logs/mysql" ]

RUN rm -rf /var/lib/mysql && ln -s /data/mysql /var/lib

ENTRYPOINT ["/app/docker-entrypoint.sh"]
ENV MYSQL_ROOT_PASSWORD=aidevops \
    MYSQL_DATABASE=admian \
    MYSQL_USER=dba_admin \
    MYSQL_PASSWORD=mt8jt2bl

EXPOSE 3306
CMD ["mysqld_safe"]
