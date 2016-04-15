FROM mdillon/postgis:9.4
MAINTAINER Peter Korduan <peter.korduan@gdi-service.de>

ENV ORACLE_MAJOR 12.1
ENV ORACLE_VERSION 12.1.0.2.0-1

RUN apt-get update && apt-get install -y \
  postgresql-server-dev-9.4 \
  alien \
  zip \
  libaio1

WORKDIR /tmp

COPY oracle/oracle-instantclient${ORACLE_MAJOR}-basic-${ORACLE_VERSION}.x86_64.rpm \
     oracle/oracle-instantclient${ORACLE_MAJOR}-sqlplus-${ORACLE_VERSION}.x86_64.rpm \
     oracle/oracle-instantclient${ORACLE_MAJOR}-jdbc-${ORACLE_VERSION}.x86_64.rpm \
     oracle/oracle-instantclient${ORACLE_MAJOR}-devel-${ORACLE_VERSION}.x86_64.rpm ./

RUN alien -i oracle-instantclient${ORACLE_MAJOR}-basic-${ORACLE_VERSION}.x86_64.rpm && \
    alien -i  oracle-instantclient${ORACLE_MAJOR}-sqlplus-${ORACLE_VERSION}.x86_64.rpm && \
    alien -i  oracle-instantclient${ORACLE_MAJOR}-jdbc-${ORACLE_VERSION}.x86_64.rpm && \
    alien -i  oracle-instantclient${ORACLE_MAJOR}-devel-${ORACLE_VERSION}.x86_64.rpm

ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/usr/lib/oracle/12.1/client64/lib
ENV PATH $PATH:/usr/lib/oracle/12.1/client64/bin
ENV ORACLE_HOME /usr/lib/oracle/12.1/client64/bin

ADD https://github.com/laurenz/oracle_fdw/archive/master.zip ./oracle_fdw.zip

RUN unzip -q oracle_fdw.zip

WORKDIR /tmp/oracle_fdw-master

RUN make && \
    make install

