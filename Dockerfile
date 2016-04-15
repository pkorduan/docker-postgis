FROM mdillon/postgis:latest
MAINTAINER Peter Korduan <peter.korduan@gdi-service.de>

ENV ORACLE_MAJOR_VERSION 12.1
ENV ORACEL_MINOR_VERSION 0.2.0-1

RUN apt-get update && apt-get install -y \
  alien \
  zip

ADD oracle-instantclient${ORACLE_MAJOR_VERSION}-basic-${ORACLE_MAJOR_VERSION}.${ORACLE_MINOR_VERSION}.x86_64.rpm /tmp
ADD oracle-instantclient${ORACLE_MAJOR_VERSION}-sqlplus-${ORACLE_MAJOR_VERSION}.${ORACLE_MINOR_VERSION}.x86_64.rpm /tmp
ADD oracle-instantclient${ORACLE_MAJOR_VERSION}-jdbc-${ORACLE_MAJOR_VERSION}.${ORACLE_MINOR_VERSION}.x86_64.rpm /tmp
ADD oracle-instantclient${ORACLE_MAJOR_VERSION}-devel-${ORACLE_MAJOR_VERSION}.${ORACLE_MINOR_VERSION}.x86_64.rpm /tmp

ADD https://github.com/laurenz/oracle_fdw/archive/master.zip /tmp/oracle_fdw.zip

WORKDIR /tmp

RUN alien -i oracle-instantclient${ORACLE_MAJOR_VERSION}-basic-${ORACLE_MAJOR_VERSION}.${ORACLE_MINOR_VERSION}.x86_64.rpm && \
    alien -i  oracle-instantclient${ORACLE_MAJOR_VERSION}-sqlplus-${ORACLE_MAJOR_VERSION}.${ORACLE_MINOR_VERSION}.x86_64.rpm && \
    alien -i  oracle-instantclient${ORACLE_MAJOR_VERSION}-jdbc-${ORACLE_MAJOR_VERSION}.${ORACLE_MINOR_VERSION}.x86_64.rpm && \
    alien -i  oracle-instantclient${ORACLE_MAJOR_VERSION}-devel-${ORACLE_MAJOR_VERSION}.${ORACLE_MINOR_VERSION}.x86_64.rpm

RUN unzip -q oracle_fdw.zip

WORKDIR /tmp/oracle_fdw-master

RUN make && \
    make install
