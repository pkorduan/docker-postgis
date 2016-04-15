FROM mdillon/postgis:latest
MAINTAINER Peter Korduan <peter.korduan@gdi-service.de>

RUN apt-get update && apt-get install -y \
  alien \
  zip

ADD oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm /tmp
ADD oracle-instantclient12.1-sqlplus-12.1.0.2.0-1.x86_64.rpm /tmp
ADD oracle-instantclient12.1-odbc-12.1.0.2.0-1.x86_64.rpm /tmp
ADD oracle-instantclient12.1-jdbc-12.1.0.2.0-1.x86_64.rpm /tmp
ADD oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm /tmp
ADD oracle-instantclient12.1-tools-12.1.0.2.0-1.x86_64.rpm /tmp

ADD https://github.com/laurenz/oracle_fdw/archive/master.zip /tmp/oracle_fdw.zip

WORKDIR /tmp

RUN alien -i oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm && \
    alien -i  oracle-instantclient12.1-sqlplus-12.1.0.2.0-1.x86_64.rpm && \
    alien -i  oracle-instantclient12.1-odbc-12.1.0.2.0-1.x86_64.rpm && \
    alien -i  oracle-instantclient12.1-jdbc-12.1.0.2.0-1.x86_64.rpm && \
    alien -i  oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm && \
    alien -i  oracle-instantclient12.1-tools-12.1.0.2.0-1.x86_64.rpm

RUN unzip -q oracle_fdw.zip

WORKDIR /tmp/oracle_fdw-master

RUN make && \
    make install
