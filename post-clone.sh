#!/bin/bash

# Repo-Wurzel = Verzeichnis dieses Skripts (unabhängig vom aktuellen Arbeitsverzeichnis)
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Verzeichnisse anlegen + Ownership für den Container-User (uid/gid 999)
mkdir -p "$REPO_DIR/data" "$REPO_DIR/logs" "$REPO_DIR/pgbackrest" "$REPO_DIR/config/pgbackrest"

# config/ ist host-spezifisch (nicht in Git). Fehlende Dateien als Link auf die Vorlagen im Repo,
# vorhandene (z. B. von Ansible erzeugte) bleiben unangetastet
for f in postgresql.conf pg_hba.conf .pgpass; do
    [ -e "$REPO_DIR/config/$f" ] || ln -s "../build/sources/$f" "$REPO_DIR/config/$f"
done

chown -R 999:999 "$REPO_DIR/."

# config/pgbackrest enthält SSH-Key und Cipher-Passphrase für repo2
chmod 700 "$REPO_DIR/config/pgbackrest"

# .pgpass muss 0600 sein, sonst ignoriert psql sie (Git speichert nur das x-Bit)
chmod 600 "$REPO_DIR/build/sources/.pgpass"
[ -L "$REPO_DIR/config/.pgpass" ] || chmod 600 "$REPO_DIR/config/.pgpass"

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
30 3 * * *  root  docker exec $CONTAINER /usr/local/bin/logs.sh /var/log/pgsql 7
EOF
chmod 644 /etc/cron.d/docker-postgis-logs
echo "Log-Cronjob installiert: /etc/cron.d/docker-postgis-logs ($CONTAINER)"
