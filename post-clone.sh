#!/bin/bash

# Repo-Wurzel = Verzeichnis dieses Skripts (unabhängig vom aktuellen Arbeitsverzeichnis)
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Verzeichnisse anlegen + Ownership für den Container-User (uid/gid 999)
mkdir -p "$REPO_DIR/data" "$REPO_DIR/logs" "$REPO_DIR/pgbackrest"
chown -R 999:999 "$REPO_DIR/."

# Host-Cronjob für die Log-Wartung einrichten (läuft im Container via docker exec).
# /etc/cron.d/ -> Datei wird bei jedem Lauf überschrieben => idempotent.
# Containername wie in docker-compose.yml: ${NETWORK_NAME}_${SERVICE_NAME} (mit Defaults).
NETWORK_NAME="$(grep -E '^NETWORK_NAME=' "$REPO_DIR/.env" 2>/dev/null | cut -d= -f2- | tr -d '"')"
SERVICE_NAME="$(grep -E '^SERVICE_NAME=' "$REPO_DIR/.env" 2>/dev/null | cut -d= -f2- | tr -d '"')"
CONTAINER="${NETWORK_NAME:-kvwmap_prod}_${SERVICE_NAME:-pgsql}"

cat > /etc/cron.d/docker-postgis-logs <<EOF
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# Täglich 03:30: PostgreSQL-Logs im Container komprimieren, nach 90 Tagen löschen
30 3 * * *  root  docker exec $CONTAINER /usr/local/bin/logs.sh /var/log/pgsql 90
EOF
chmod 644 /etc/cron.d/docker-postgis-logs
echo "Log-Cronjob installiert: /etc/cron.d/docker-postgis-logs ($CONTAINER)"
