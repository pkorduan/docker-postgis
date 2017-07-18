FROM postgres:9.4
MAINTAINER Peter Korduan <pkorduan@gdi-service.de>

ENV POSTGIS_MAJOR 2.1
ENV PG_ROUTING_MAJOR 2.0
ENV TERM xterm
ENV LC_ALL de_DE.UTF-8
ENV LANG de_DE.UTF-8
ENV LANGUAGE de_DE.UTF-8

RUN apt-get update && apt-get install -y \
  apt-utils \
  locales \
  locales-all \
  postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
  postgresql-9.4-pgrouting \
  postgis \
  && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    vim \
    ntp

RUN sed -i \
        -e "s|# alias ls=|alias ls=|g" \
        -e "s|# alias ll=|alias ll=|g" \
        -e "s|# alias rm=|alias rm=|g" \
    ~/.bashrc && \
    echo $TZ > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN mkdir -p /docker-entrypoint-initdb.d
COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/postgis.sh
