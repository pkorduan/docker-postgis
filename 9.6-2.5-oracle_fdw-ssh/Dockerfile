FROM postgres:9.6.11
ARG POSTGRES_MAJOR=9.6
ARG POSTGIS_MAJOR=2.5
ARG PG_ROUTING_MAJOR=2.0

MAINTAINER Peter Korduan <pkorduan@gdi-service.de>

RUN localedef -i de_DE -c -f UTF-8 -A /usr/share/locale/locale.alias de_DE.UTF-8

ENV POSTGRES_MAJOR $POSTGRES_MAJOR
ENV POSTGIS_MAJOR $POSTGIS_MAJOR
ENV PG_ROUTING_MAJOR $PG_ROUTING_MAJOR
ENV TERM xterm
ENV LC_ALL de_DE.UTF-8
ENV LANG de_DE.UTF-8
ENV LANGUAGE de_DE.UTF-8

RUN sed -i \
        -e "s|# alias ls=|alias ls=|g" \
        -e "s|# alias ll=|alias ll=|g" \
        -e "s|# alias rm=|alias rm=|g" \
        ~/.bashrc && \
    echo $TZ > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get update && apt-get install -y \
  alien \
  apt-utils \
  build-essential \
  libaio1 \
  libaio-dev \
  locales \
  locales-all \
  ntp \
  postgis \
  postgresql-$PG_MAJOR \
  postgresql-$PG_MAJOR-pgrouting \
  postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
  postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR-scripts \
  postgresql-server-dev-$PG_MAJOR \
  vim \
  wget \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /docker-entrypoint-initdb.d

ADD sources/postgresql.conf.kvwmap /usr/share/postgresql/postgresql.conf.kvwmap

RUN mv /usr/share/postgresql/postgresql.conf.sample /usr/share/postgresql/postgressql.conf.sample_original && \
    cp /usr/share/postgresql/postgresql.conf.kvwmap /usr/share/postgresql/postgresql.conf.sample

ADD sources /usr/local

WORKDIR /usr/local

RUN alien -i oracle-instantclient11.2-basic-11.2.0.1.0-1.x86_64.rpm && \
    alien -i oracle-instantclient11.2-devel-11.2.0.1.0-1.x86_64.rpm && \
    alien -i oracle-instantclient11.2-sqlplus-11.2.0.1.0-1.x86_64.rpm

RUN tar xvfz oracle_fdw-ORACLE_FDW_1_5_0.tar.gz

WORKDIR /usr/local/oracle_fdw-ORACLE_FDW_1_5_0

RUN make && \
    make install

RUN cp /usr/lib/oracle/11.2/client64/lib/libclntsh.so.11.1 /usr/lib && \
    cp /usr/lib/oracle/11.2/client64/lib/libnnz11.so /usr/lib

ENV ORACLE_HOME "/usr/lib/oracle/11.2/client64"
ENV LD_LIBRARY_PATH "/usr/lib/oracle/11.2/client64/lib:/usr/lib/oracle/11.2/client64"

RUN apt-get update && apt-get install -y \
  openssh-server

COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/postgis.sh

# docker run --rm --name pgssh -e TERM=linux -e COLUMNS=180 -e LINES=200 -e POSTGRES_USER=postgres -e POSTGRES_DB=postgres -e PG_MAJOR=2.6 -e PGPASSFILE=~/.pgpass -v /home/gisadmin/www/data/postgres_data_test:/var/www pkorduan/postgis:9.6-2.5-ssh -d