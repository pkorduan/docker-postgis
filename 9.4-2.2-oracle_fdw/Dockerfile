FROM postgres:9.4
MAINTAINER Peter Korduan <peter.korduan@gdi-service.de>

ENV PG_MAJOR 9.4
ENV POSTGIS_MAJOR 2.1
ENV PG_ROUTING_MAJOR 2.0

RUN apt-get update && apt-get install -y --no-install-recommends \
  alien \
  apt-utils \
  build-essential \
  libaio1 \
  libaio-dev \
  postgresql-9.4 \
  postgresql-server-dev-9.4 \
  postgis-2.1 \
  wget \
  && rm -rf /var/lib/apt/lists/*

ADD sources /usr/local

WORKDIR /usr/local

RUN alien -i oracle-instantclient11.2-basic-11.2.0.1.0-1.x86_64.rpm && \
    alien -i oracle-instantclient11.2-devel-11.2.0.1.0-1.x86_64.rpm && \
    alien -i oracle-instantclient11.2-sqlplus-11.2.0.1.0-1.x86_64.rpm

#RUN ln -s /usr/lib/oracle/11.1.0.1 /usr/lib/oracle/11.1 && \
#    cp /usr/lib/oracle/11.1.0.1/client64/lib/libclntsh.so.11.1 /usr/lib && \
#    cp /usr/lib/oracle/11.1.0.1/client64/lib/libnnz11.so /usr/lib && \
#    export ORACLE_HOME=/usr/lib/oracle/11.1/client64 && \
#    export LD_LIBRARY_PATH=/usr/lib/oracle/11.1.0.1/client64/lib/ && \
#    export PATH=$PATH:$ORACLE_HOME/bin && \
#    ldconfig

RUN tar xvfz oracle_fdw-ORACLE_FDW_1_5_0.tar.gz

WORKDIR /usr/local/oracle_fdw-ORACLE_FDW_1_5_0

RUN make && \
    make install

RUN mkdir -p /docker-entrypoint-initdb.d
COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/postgis.sh
