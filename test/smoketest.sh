#!/bin/bash
# Smoketest für das Image: startet einen Wegwerf-Container ohne Volumes und prüft
# Init-Skripte, alle Extensions, pgBackRest, Locale/Zeitzone.
#
# Aufruf: test/smoketest.sh [image]   ohne image wird ./build als docker-postgis:smoketest gebaut
# Exit-Code = Anzahl fehlgeschlagener Checks
set -uo pipefail
cd "$(dirname "$0")/.."

IMAGE=${1:-}
if [ -z "$IMAGE" ]; then
    IMAGE=docker-postgis:smoketest
    docker build -q -t "$IMAGE" build >/dev/null || exit 1
fi

NAME=pg-smoketest-$$
PW=smoke
trap 'docker rm -f "$NAME" >/dev/null 2>&1' EXIT

docker run -d --name "$NAME" \
    -e POSTGRES_PASSWORD=$PW -e INITDB_KVWMAPSP_DB=true -e INITDB_KVWMAP_PASSWORD=kvwmap \
    "$IMAGE" >/dev/null || exit 1

# Init ist durch, wenn der Server auf TCP antwortet (der temporäre Init-Server lauscht nur auf dem Socket)
echo "warte auf Init ..."
for i in $(seq 1 90); do
    if [ "$(docker inspect -f '{{.State.Running}}' "$NAME")" != true ]; then
        docker logs "$NAME"; echo "FEHLER: Container hat sich beendet"; exit 1
    fi
    docker exec "$NAME" pg_isready -q -h 127.0.0.1 && break
    [ "$i" -eq 90 ] && { docker logs "$NAME"; echo "FEHLER: Timeout beim Init"; exit 1; }
    sleep 2
done

FAIL=0
check() {  # check "Name" befehl...
    local name=$1 out; shift
    if out=$("$@" 2>&1); then
        echo "OK      $name"
    else
        echo "FEHLER  $name"; echo "$out" | sed 's/^/        /'; FAIL=$((FAIL + 1))
    fi
}
sql() {  # sql db sql [user] [passwort]
    docker exec -e PGPASSWORD="${4:-$PW}" "$NAME" \
        psql -X -q -At -v ON_ERROR_STOP=1 -h 127.0.0.1 -U "${3:-postgres}" -d "$1" -c "$2"
}
ex() { docker exec -e PGPASSWORD=$PW "$NAME" "$@"; }  # Prod: Passwort aus gemounteter .pgpass

echo "--- Image"
check "PostGIS ist 3.1 (aus Quellcode)" sql postgres "DO \$\$BEGIN ASSERT (SELECT default_version FROM pg_available_extensions WHERE name='postgis') LIKE '3.1%'; END\$\$"
check "alle .so in pkglibdir auflösbar" bash -c "! docker exec $NAME sh -c 'ldd /usr/lib/postgresql/14/lib/*.so' | grep 'not found'"
check "pgBackRest kann SFTP (libssh2)" bash -c "docker exec $NAME pgbackrest help backup repo-type | grep -q sftp"
check "Locale/Zeitzone" sql postgres "DO \$\$BEGIN ASSERT current_setting('lc_time')='de_DE.utf8'; ASSERT current_setting('TimeZone')='Europe/Berlin'; END\$\$"

echo "--- alle Extensions anlegen (DB smoke)"
sql postgres "CREATE DATABASE smoke" >/dev/null
# pg_cron geht nur in cron.database_name (postgres), die *-3 sind Aliase der PostGIS-Extensions
for ext in $(sql smoke "SELECT name FROM pg_available_extensions WHERE name NOT IN ('plpgsql','pg_cron') AND name NOT LIKE '%-3' ORDER BY name"); do
    check "CREATE EXTENSION $ext" sql smoke "CREATE EXTENSION IF NOT EXISTS \"$ext\" CASCADE"
done

echo "--- Extensions funktional"
check "postgis: Transformation 4326 -> 25833" sql smoke "DO \$\$BEGIN ASSERT ST_X(ST_Transform(ST_SetSRID(ST_MakePoint(12.1,54.1),4326),25833)) BETWEEN 300000 AND 400000; END\$\$"
check "postgis_raster" sql smoke "SELECT ST_Width(ST_AddBand(ST_MakeEmptyRaster(10,10,0,0,1),'8BUI'::text))"
check "postgis_topology" sql smoke "SELECT topology.CreateTopology('smoke_topo',25833)"
check "postgis_sfcgal" sql smoke "SELECT ST_Volume(ST_Extrude(ST_GeomFromText('POLYGON((0 0,1 0,1 1,0 1,0 0))'),0,0,1))"
check "postgis_tiger_geocoder" sql smoke "SELECT normalize_address('1 Main St, Boston, MA 02101')"
check "pgrouting: Dijkstra" sql smoke "DO \$\$BEGIN ASSERT (SELECT max(agg_cost) FROM pgr_dijkstra('SELECT * FROM (VALUES (1,1,2,1.0,1.0),(2,2,3,2.0,2.0)) e(id,source,target,cost,reverse_cost)',1,3)) = 3; END\$\$"
check "pgcrypto" sql smoke "DO \$\$BEGIN ASSERT crypt('x', gen_salt('bf')) LIKE '\$2a\$%'; END\$\$"
check "oracle_fdw: Instant Client lädt" sql smoke "SELECT oracle_diag()"
check "mysql_fdw: Server anlegen" sql smoke "CREATE SERVER smoke_mysql FOREIGN DATA WRAPPER mysql_fdw OPTIONS (host '127.0.0.1', port '3306')"
check "tds_fdw: Server anlegen" sql smoke "CREATE SERVER smoke_tds FOREIGN DATA WRAPPER tds_fdw OPTIONS (servername '127.0.0.1', port '1433')"
check "postgres_fdw: Abfrage über Loopback" sql smoke "CREATE SERVER loop FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host '127.0.0.1', dbname 'postgres'); CREATE USER MAPPING FOR postgres SERVER loop OPTIONS (user 'postgres', password '$PW'); CREATE FOREIGN TABLE ft (datname name) SERVER loop OPTIONS (table_name 'pg_database', schema_name 'pg_catalog'); SELECT count(*) FROM ft"

echo "--- Init-Skripte"
check "pg_cron: Jobs aus Init vorhanden" sql postgres "DO \$\$BEGIN ASSERT (SELECT count(*) FROM cron.job) >= 2; END\$\$"
check "pg_cron: Job anlegen/löschen" sql postgres "SELECT cron.unschedule(cron.schedule('smoke','0 0 1 1 *','SELECT 1'))"
check "pg_track_settings: Snapshot" sql postgres "SELECT pg_track_settings_snapshot()"
check "pgmonitor_bgw refresht Matviews" sql kvwmapsp "DO \$\$BEGIN ASSERT (SELECT max(last_run) FROM monitor.metric_matviews) IS NOT NULL; END\$\$"
check "kvwmapsp: kvwmap Login, kein Superuser" sql kvwmapsp "DO \$\$BEGIN ASSERT NOT (SELECT rolsuper FROM pg_roles WHERE rolname=current_user); END\$\$" kvwmap kvwmap
check "kvwmapsp: postgis, pgcrypto, pgmonitor" sql kvwmapsp "DO \$\$BEGIN ASSERT (SELECT count(*) FROM pg_extension WHERE extname IN ('postgis','pgcrypto','pgmonitor')) = 3; END\$\$"
check "kvwmapsp: spatial_ref_sys mit MV-Gittern" sql kvwmapsp "DO \$\$BEGIN ASSERT (SELECT proj4text FROM spatial_ref_sys WHERE srid=31968) LIKE '%MVTR2010.gsb%'; END\$\$"
check "kvwmapsp: zabbix liest Monitoring" sql kvwmapsp "SELECT * FROM monitor.zabbix_wal_activity; SELECT * FROM monitor.transactions" zabbix zabbix

echo "--- pgBackRest / Logs"
check "pgbackrest check" ex pgbackrest --stanza=local check
check "pgbackrest Full-Backup" ex pgbackrest --stanza=local --type=full backup
check "pgbackrest info: Status ok" bash -c "docker exec -e PGPASSWORD=$PW $NAME pgbackrest --stanza=local --output=json info | jq -e '.[0].status.code == 0'"
check "Logdatei in /var/log/pgsql" bash -c "docker exec $NAME ls /var/log/pgsql | grep -q ."

echo
[ "$FAIL" -eq 0 ] && echo "ALLES OK" || echo "$FAIL Check(s) fehlgeschlagen"
exit "$FAIL"
