FROM postgres:9.4
MAINTAINER Peter Korduan <peter.korduan@gdi-service.de>

ENV POSTGIS_MAJOR 2.3
ENV PG_ROUTING_MAJOR 2.0

RUN apt-get update && apt-get install -y --no-install-recommends \
  apt-utils \
  postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
  postgis \
  && rm -rf /var/lib/apt/lists/*

#RUN alias psql='LD_PRELOAD=/lib/x86_64-linux-gnu/libreadline.so.6.3 psql'

RUN mkdir -p /docker-entrypoint-initdb.d
COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/postgis.sh
