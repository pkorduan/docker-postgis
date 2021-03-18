#!/bin/sh
echo "Gesetzte Umgebungsvariablen:"
echo "POSTGRES_USER: "$POSTGRES_USER
echo "POSTGRES_DB: "$POSTGRES_DB
echo "PG_MAJOR: "$PG_MAJOR

set -e

# Perform all actions as $POSTGRES_USER
export PGUSER="$POSTGRES_USER"

# Create the 'template_postgis' template db
psql --dbname="$POSTGRES_DB" <<- 'EOSQL'
CREATE DATABASE template_postgis;
UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template_postgis';
EOSQL

echo "Loading PostGIS into $DB via CREATE EXTENSION"
psql --dbname="$DB" <<-'EOSQL'
	CREATE EXTENSION postgis;
	CREATE EXTENSION postgis_topology;
	CREATE EXTENSION fuzzystrmatch;
	CREATE EXTENSION postgis_tiger_geocoder;
	CREATE EXTENSION pgrouting;
EOSQL