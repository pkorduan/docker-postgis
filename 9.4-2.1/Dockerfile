FROM postgres:9.4
MAINTAINER Mike Dillon <mike@appropriate.io>

ENV POSTGIS_MAJOR 2.1
ENV POSTGIS_VERSION 2.1.7+dfsg-3~94.git954a8d0.pgdg80+1
ENV PG_ROUTING_MAJOR 2.0
ENV PG_ROUTING_VERSION 2.0.0-3.pgdg80+1

RUN apt-get update && apt-get install -y --no-install-recommends \
  postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR=$POSTGIS_VERSION \
  postgresql-$PG_MAJOR-pgrouting=$PG_ROUTING_VERSION \
  postgis=$POSTGIS_VERSION \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /docker-entrypoint-initdb.d
COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/postgis.sh
