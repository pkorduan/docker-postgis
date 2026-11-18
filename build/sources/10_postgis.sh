#!/bin/bash
# Entspricht /docker-entrypoint-initdb.d/10_postgis.sh aus dem Image postgis/postgis
# (hier nötig, weil das Image auf postgres:14 basiert und PostGIS selbst baut)
set -e

export PGUSER="$POSTGRES_USER"

"${psql[@]}" <<- 'EOSQL'
CREATE DATABASE template_postgis IS_TEMPLATE true;
EOSQL

for DB in template_postgis "$POSTGRES_DB"; do
	echo "Loading PostGIS extensions into $DB"
	"${psql[@]}" --dbname="$DB" <<- 'EOSQL'
		CREATE EXTENSION IF NOT EXISTS postgis;
		CREATE EXTENSION IF NOT EXISTS postgis_topology;
		-- Reconnect to update pg_setting.resetval
		\c
		CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
		CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;
EOSQL
done
