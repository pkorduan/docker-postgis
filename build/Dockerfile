FROM postgres:14.25-trixie

# PostGIS 3.1 gibt es nicht mehr als Paket (PGDG hat für PG 14 nur 3.6/3.7) -> unten aus dem Quellcode gebaut.
# Paket-PostGIS sperren, damit apt es nicht als Abhängigkeit nachzieht
RUN printf 'Package: postgresql-14-postgis* postgis\nPin: release *\nPin-Priority: -1\n' > /etc/apt/preferences.d/no-postgis-pkg

RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-14-mysql-fdw \
    postgresql-14-oracle-fdw \
#    postgresql-contrib-15 \
    postgresql-server-dev-14 \
    pgstat \
    postgresql-14-pg-track-settings \
    postgresql-14-cron \
#    postgresql-15-pgaudit \
#    postgresql-15-powa \
#    postgresql-15-pg-qualstats \
#    postgresql-15-pg-stat-kcache \ 
#    postgresql-15-hypopg \
    pgbackrest \
#    alien \
#    apt-utils \
    build-essential \
#    libaio1 \
#    libaio-dev \
    locales \
    locales-all \
    htop \
    wget \
    nano \
    tzdata \
    tree \
    jq \
    zstd \
    git \
    libsybdb5 freetds-dev freetds-common \
    psmisc

#######################################
# PostGIS 3.1 und pgRouting 3.x aus dem Quellcode
#######################################

ARG POSTGIS_VERSION=3.1.13
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libgeos-dev libproj-dev proj-data libgdal-dev libxml2-dev libjson-c-dev \
        libprotobuf-c-dev protobuf-c-compiler libsfcgal-dev pkg-config \
        cmake libboost-graph-dev; \
    cd /tmp; \
    wget -qO- "https://download.osgeo.org/postgis/source/postgis-${POSTGIS_VERSION}.tar.gz" | tar -xz; \
    cd "postgis-${POSTGIS_VERSION}"; \
    # neuere GDAL definiert MIN() nicht mehr, GCC 14 bricht ab -> Min() aus PostgreSQL nehmen
    sed -i 's/\bMIN(/Min(/g' raster/rt_pg/rtpg_geometry.c; \
    ./configure --with-sfcgal; \
    make -j"$(nproc)"; \
    make install; \
    cd /; rm -rf "/tmp/postgis-${POSTGIS_VERSION}"

# pgRouting-Paket aus PGDG hängt am Paket-PostGIS und ist 4.x (viele Funktionen entfernt) -> letztes 3.x selbst bauen
ARG PGROUTING_VERSION=3.8.0
RUN set -eux; \
    cd /tmp; \
    wget -qO- "https://github.com/pgRouting/pgrouting/archive/v${PGROUTING_VERSION}.tar.gz" | tar -xz; \
    mkdir "pgrouting-${PGROUTING_VERSION}/build"; \
    cd "pgrouting-${PGROUTING_VERSION}/build"; \
    cmake ..; \
    make -j"$(nproc)"; \
    make install; \
    cd /; rm -rf "/tmp/pgrouting-${PGROUTING_VERSION}"

#######################################
# locale, Zeit
#######################################

#locale
RUN localedef -i de_DE -c -f UTF-8 -A /usr/share/locale/locale.alias de_DE.UTF-8
ENV LANG de_DE.utf8
RUN locale -a

#rm package lists
RUN rm -rf /var/lib/apt/lists/*

#Timezone
RUN rm /etc/localtime
RUN ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime

#######################################
# postgres extensions
#######################################

#pgbackrest settings
# Basis-Konfiguration im Image, Host-spezifisches (repo2, SSH-Key, known_hosts) wird nach /etc/pgbackrest/host gemountet
RUN rm -f /etc/pgbackrest.conf \
 && mkdir -p /etc/pgbackrest/host /var/spool/pgbackrest \
 && chown 999:999 /etc/pgbackrest/host /var/spool/pgbackrest
COPY sources/pgbackrest.conf /etc/pgbackrest/pgbackrest.conf
ENV PGBACKREST_CONFIG_INCLUDE_PATH=/etc/pgbackrest/host

#pgmonitor bauen
# https://github.com/CrunchyData/pgmonitor-extension
WORKDIR /etc/
RUN git clone https://github.com/CrunchyData/pgmonitor-extension.git && cd pgmonitor-extension && make install

#######################################
# tds_fdw
#######################################

# tds_fdw bauen (gemäß InstallDebian.md)
# Quelle: https://sources.debian.org/src/tds-fdw/2.0.4-1/InstallDebian.md
ARG TDS_FDW_VERSION=2.0.4
WORKDIR /tmp
RUN set -eux; \
    wget -qO- "https://github.com/tds-fdw/tds_fdw/archive/v${TDS_FDW_VERSION}.tar.gz" | tar -xz; \
    cd "tds_fdw-${TDS_FDW_VERSION}"; \
    make USE_PGXS=1; \
    make USE_PGXS=1 install; \
    cd /; \
    rm -rf "/tmp/tds_fdw-${TDS_FDW_VERSION}"

#######################################
# Konfiguration und Init-Dateien
#######################################

#postgresql default settings
ADD --chown=postgres:postgres sources/postgresql.conf sources/pg_hba.conf /var/lib/postgresql/config/

# initdb scripte
COPY sources/10_postgis.sh /docker-entrypoint-initdb.d/
COPY sources/20_pg_cron.sh /docker-entrypoint-initdb.d/
COPY sources/30_init_pgbackrest.sh /docker-entrypoint-initdb.d/
COPY sources/40_pg_track_settings.sh /docker-entrypoint-initdb.d/
COPY sources/50_kvwmapsp.sh /docker-entrypoint-initdb.d/

# Log-Wartungsskript (wird per Host-Cron via docker exec aufgerufen)
COPY sources/logs.sh /usr/local/bin/logs.sh
RUN chmod +x /usr/local/bin/logs.sh

#aliase
RUN echo "alias ls='ls $LS_OPTIONS' \n alias ll='ls $LS_OPTIONS -l' \n alias rm='rm -i' \n" >> /etc/bash.bashrc

# Volumes haben richtige Rechte (muss vor USER postgres stehen)
RUN mkdir -p /var/log/pgsql /pgbackrest \
 && chown postgres:postgres /var/log/pgsql /pgbackrest

#set work env
WORKDIR /var/lib/postgresql
USER postgres

#env
ENV PGPASSFILE="/var/lib/postgresql/config/.pgpass"
ENV PGSQL_DB="postgres"
ENV PGSQL_USER="postgres"

CMD [ "docker-entrypoint.sh", "postgres", "-c", "config_file=/var/lib/postgresql/config/postgresql.conf" ]
