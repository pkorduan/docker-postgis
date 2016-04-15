FROM mdillon/postgis:latest
MAINTAINER Peter Korduan <peter.korduan@gdi-service.de>

ENV ORACLE_MAJOR 12.1
ENV ORACLE_VERSION 12.1.0.2.0-1

RUN apt-get update && apt-get install -y \
  postgresql-server-dev-${PG_VERSION} \
  alien \
  zip

ADD oracle/oracle-instantclient${ORACLE_MAJOR}-basic-${ORACLE_VERSION}.x86_64.rpm /tmp
ADD oracle/oracle-instantclient${ORACLE_MAJOR}-sqlplus-${ORACLE_VERSION}.x86_64.rpm /tmp
ADD oracle/oracle-instantclient${ORACLE_MAJOR}-jdbc-${ORACLE_VERSION}.x86_64.rpm /tmp
ADD oracle/oracle-instantclient${ORACLE_MAJOR}-devel-${ORACLE_VERSION}.x86_64.rpm /tmp

ADD https://github.com/laurenz/oracle_fdw/archive/master.zip /tmp/oracle_fdw.zip

WORKDIR /tmp

RUN alien -i oracle-instantclient${ORACLE_MAJOR}-basic-${ORACLE_VERSION}.x86_64.rpm && \
    alien -i  oracle-instantclient${ORACLE_MAJOR}-sqlplus-${ORACLE_VERSION}.x86_64.rpm && \
    alien -i  oracle-instantclient${ORACLE_MAJOR}-jdbc-${ORACLE_VERSION}.x86_64.rpm && \
    alien -i  oracle-instantclient${ORACLE_MAJOR}-devel-${ORACLE_VERSION}.x86_64.rpm

RUN unzip -q oracle_fdw.zip

WORKDIR /tmp/oracle_fdw-master

RUN make && \
    make install
