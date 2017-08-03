FROM postgres:9.4
ARG POSTGRES_MAJOR=9.4
ARG POSTGIS_MAJOR=2.3
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
  apt-utils \
  locales \
  locales-all \
  ntp \
  postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
  postgresql-9.4-pgrouting \
  postgis \
  vim

RUN rm -rf /var/lib/apt/lists/*

RUN mkdir -p /docker-entrypoint-initdb.d
COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/postgis.sh
