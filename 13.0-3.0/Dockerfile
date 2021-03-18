FROM postgis/postgis:13-3.0
ARG POSTGRES_MAJOR=13.0
ARG POSTGIS_MAJOR=3.0
ARG PG_ROUTING_MAJOR=2.0

MAINTAINER Peter Korduan <peter.korduan@gdi-service.de>

RUN localedef -i de_DE -c -f UTF-8 -A /usr/share/locale/locale.alias de_DE.UTF-8

COPY ./sources/locale.md /locale.md
#RUN cat locale.md | xargs -i /usr/glibc-compat/bin/localedef -i {} -f UTF-8 {}.UTF-8

ENV LANG de_DE.UTF-8
ENV LANGUAGE de_DE.UTF-8
ENV POSTGRES_MAJOR $POSTGRES_MAJOR
ENV POSTGIS_MAJOR $POSTGIS_MAJOR
ENV PG_ROUTING_MAJOR $PG_ROUTING_MAJOR
ENV TERM xterm
ENV LC_ALL de_DE.UTF-8

#RUN echo $TZ > /etc/timezone

#RUN mkdir -p /docker-entrypoint-initdb.d

#ADD sources/postgresql.conf.kvwmap /usr/share/postgresql/postgresql.conf.kvwmap

#RUN mv /usr/share/postgresql/postgresql.conf.sample /usr/share/postgresql/postgressql.conf.sample_original && \
#    cp /usr/share/postgresql/postgresql.conf.kvwmap /usr/share/postgresql/postgresql.conf.sample

#COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/postgis.sh

# run for testing with command
# docker run --name pgsql13 -h pgsql13-container -p 5433:5432 -d pkorduan/postgis:13.0-3.0

