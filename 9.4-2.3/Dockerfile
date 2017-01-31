FROM postgres:9.4
MAINTAINER Peter Korduan <pkorduan@gdi-service.de>

ENV POSTGIS_MAJOR 2.3
ENV PG_ROUTING_MAJOR 2.0

RUN apt-get update && apt-get install -y \
  apt-utils \
  postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
<<<<<<< HEAD
  postgresql-9.4-pgrouting \
=======
>>>>>>> 73e3dab2b0a3eb4b6ca1556eac59689b9b5bc8ab
  postgis \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /docker-entrypoint-initdb.d
COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/postgis.sh
