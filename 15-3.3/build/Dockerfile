FROM postgis/postgis:15-3.3

#locale
RUN localedef -i de_DE -c -f UTF-8 -A /usr/share/locale/locale.alias de_DE.UTF-8
ENV LANG de_DE.utf8
RUN locale -a

#apt
RUN apt-get update && apt-get install -y \
    postgresql-15-mysql-fdw \
    postgresql-15-pgrouting \
#    postgresql-contrib-15 \
    postgresql-server-dev-15 \
    pgstat \
    postgresql-15-pg-track-settings \
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
    git

#Oracle FDW lkee only
ADD sources/oracle /usr/local/oracle

WORKDIR /usr/local/oracle

RUN alien --scripts -i oracle-instantclient-basic-21.8.0.0.0-1.x86_64.rpm && \
    alien --scripts -i oracle-instantclient-sqlplus-21.8.0.0.0-1.el8.x86_64.rpm && \
    alien --scripts -i oracle-instantclient-devel-21.8.0.0.0-1.el8.x86_64.rpm

RUN cp /usr/lib/oracle/21/client64/lib/libclntsh.so.21.1 /usr/lib && \
    cp /usr/lib/oracle/21/client64/lib/libnnz21.so /usr/lib

ENV ORACLE_HOME "/usr/lib/oracle/21/client64"
ENV LD_LIBRARY_PATH "/usr/lib/oracle/21/client64/lib:/usr/lib/oracle/21/client64"

RUN wget https://github.com/laurenz/oracle_fdw/archive/refs/tags/ORACLE_FDW_2_5_0.tar.gz && \
    tar xvfz ORACLE_FDW_2_5_0.tar.gz

WORKDIR /usr/local/oracle/oracle_fdw-ORACLE_FDW_2_5_0

RUN make && \
    make install

RUN rm -rdf /usr/local/oracle

#Timezone
RUN rm /etc/localtime
RUN ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime

#rm package lists
RUN rm -rf /var/lib/apt/lists/*

#postgresql settings
ADD --chown=postgres:postgres sources/postgresql.conf sources/pg_hba.conf /var/lib/postgresql/config/
ADD --chown=postgres:postgres sources/conf.d /var/lib/postgresql/config/conf.d

#pgbackrest setting
RUN mkdir -p /etc/pgbackrest/conf.d
COPY sources/pgbackrest.local.conf /etc/pgbackrest/conf.d
RUN chown -R 999.999 /etc/pgbackrest/conf.d
RUN rm /etc/pgbackrest.conf
COPY sources/30_init_pgbackrest.sh /docker-entrypoint-initdb.d/

#pg_cron
WORKDIR /usr/local/
RUN git clone https://github.com/citusdata/pg_cron.git
WORKDIR /usr/local/pg_cron
RUN make && PATH=$PATH make install
COPY sources/20_pg_cron.sql /docker-entrypoint-initdb.d/

#pg_track_settings
COPY sources/40_pg_track_settings.sql /docker-entrypoint-initdb.d/

#aliase
RUN echo "alias ls='ls $LS_OPTIONS' \n alias ll='ls $LS_OPTIONS -l' \n alias rm='rm -i' \n" >> /etc/bash.bashrc

#set work env
WORKDIR /var/lib/postgresql
USER postgres


CMD [ "docker-entrypoint.sh", "postgres", "-c", "config_file=/var/lib/postgresql/config/postgresql.conf" ]
