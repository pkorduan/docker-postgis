FROM postgis/postgis:15-3.3

#locale
RUN localedef -i de_DE -c -f UTF-8 -A /usr/share/locale/locale.alias de_DE.UTF-8
ENV LANG de_DE.utf8
RUN locale -a

RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-15-mysql-fdw \
    postgresql-15-oracle-fdw \
    postgresql-15-pgrouting \
#    postgresql-contrib-15 \
    postgresql-server-dev-15 \
    pgstat \
    postgresql-15-pg-track-settings \
    postgresql-15-cron \
#    postgresql-15-pgaudit \
#    postgresql-15-powa \
#    postgresql-15-pg-qualstats \
#    postgresql-15-pg-stat-kcache \ 
#    postgresql-15-hypopg \
    pgbackrest \
    alien \
    apt-utils \
    build-essential \
    libaio1 \
    libaio-dev \
    locales \
    locales-all \
    ntp \
    htop \
    wget \
    nano \
    tzdata \
    tree \
    jq \
    postgis \
    git

#Timezone
RUN rm /etc/localtime
RUN ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime

#rm package lists
RUN rm -rf /var/lib/apt/lists/*

#postgresql settings
ADD --chown=postgres:postgres sources/postgresql.conf sources/pg_hba.conf /var/lib/postgresql/config/
ADD --chown=postgres:postgres sources/conf.d /var/lib/postgresql/config/conf.d

#pgbackrest settings
RUN mkdir -p /etc/pgbackrest/conf.d
COPY sources/pgbackrest.local.conf /etc/pgbackrest/conf.d
RUN chown -R 999.999 /etc/pgbackrest/conf.d
RUN rm /etc/pgbackrest.conf
COPY sources/30_init_pgbackrest.sh /docker-entrypoint-initdb.d/

#pg_cron settings
COPY sources/20_pg_cron.sql /docker-entrypoint-initdb.d/

#pg_track_settings
COPY sources/40_pg_track_settings.sql /docker-entrypoint-initdb.d/

#aliase
RUN echo "alias ls='ls $LS_OPTIONS' \n alias ll='ls $LS_OPTIONS -l' \n alias rm='rm -i' \n" >> /etc/bash.bashrc

#set work env
WORKDIR /var/lib/postgresql
USER postgres


CMD [ "docker-entrypoint.sh", "postgres", "-c", "config_file=/var/lib/postgresql/config/postgresql.conf" ]
