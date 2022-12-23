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

#Oracle FDW
ADD sources/oracle /usr/local/oracle

WORKDIR /usr/local/oracle

RUN alien -i oracle-instantclient11.2-basic-11.2.0.1.0-1.x86_64.rpm && \
    alien -i oracle-instantclient11.2-devel-11.2.0.1.0-1.x86_64.rpm && \
    alien -i oracle-instantclient11.2-sqlplus-11.2.0.1.0-1.x86_64.rpm

RUN cp /usr/lib/oracle/11.2/client64/lib/libclntsh.so.11.1 /usr/lib && \
    cp /usr/lib/oracle/11.2/client64/lib/libnnz11.so /usr/lib

ENV ORACLE_HOME "/usr/lib/oracle/11.2/client64"
ENV LD_LIBRARY_PATH "/usr/lib/oracle/11.2/client64/lib:/usr/lib/oracle/11.2/client64"

RUN wget https://github.com/laurenz/oracle_fdw/archive/refs/tags/ORACLE_FDW_2_5_0.tar.gz && \
    tar xvfz ORACLE_FDW_2_5_0.tar.gz

WORKDIR /usr/local/oracle/oracle_fdw-ORACLE_FDW_2_5_0

RUN make && \
    make install

RUN rm -rdf /usr/local/oracle

#Timezone
RUN rm /etc/localtime
RUN ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime

#alias
RUN sed -i \
        -e "s|# alias ls=|alias ls=|g" \
        -e "s|# alias ll=|alias ll=|g" \
        -e "s|# alias rm=|alias rm=|g" \
        ~/.bashrc

#rm package lists
RUN rm -rf /var/lib/apt/lists/*

#postgresql settings
ADD sources/postgresql.conf sources/pg_hba.conf /var/lib/postgresql/config/
RUN chown 999.999 /var/lib/postgresql/config/*

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

#set work env
WORKDIR /
USER postgres

CMD [ "docker-entrypoint.sh", "postgres", "-c", "config_file=/var/lib/postgresql/config/postgresql.conf" ]
