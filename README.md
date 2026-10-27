# docker-postgis

PostgreSQL 17 / PostGIS 3.6 Docker-Image mit zusätzlichen Erweiterungen und vorkonfigurierter Umgebung für den Einsatz mit [kvwmap](https://github.com/kvwmap/kvwmap).

Basiert auf dem offiziellen Image [`postgis/postgis:17-3.6`](https://hub.docker.com/r/postgis/postgis) (Debian trixie).

## Enthaltene Erweiterungen

| Erweiterung | Beschreibung |
|---|---|
| PostGIS | Räumliche Datenbankfunktionen |
| pgRouting | Netzwerk-Routing auf Basis von PostGIS |
| pg_cron | Zeitgesteuerte Jobs innerhalb der Datenbank |
| pg_track_settings | Aufzeichnung von Konfigurationsänderungen |
| pgmonitor | Monitoring-Metriken (CrunchyData) |
| pgBackRest | Backup und Point-in-Time Recovery |
| mysql_fdw | Foreign Data Wrapper für MySQL |
| oracle_fdw | Foreign Data Wrapper für Oracle |
| tds_fdw | Foreign Data Wrapper für MS SQL Server / Sybase (v2.0.4, aus Quellen gebaut) |
| pgstat | Erweiterte Statistiken |

## Konfiguration

- **Locale:** `de_DE.UTF-8`
- **Zeitzone:** `Europe/Berlin`
- **Textsuchkonfiguration:** `pg_catalog.german`
- **Logging:** Alle Statements mit Dauer, Verbindungen, Trennungen, Lock-Waits; Logdateien unter `/var/log/pgsql`
- **WAL-Archivierung:** aktiviert via pgBackRest (`pgbackrest --stanza local archive-push`), asynchron in alle Repos, siehe [pgBackRest](#pgbackrest)
- **PGTune-Profil:** Web-Workload, 64 GB RAM, 24 CPUs, SSD (als auskommentierte Vorlage in `build/sources/postgresql.conf` hinterlegt)

## Verzeichnisstruktur

```
.
├── build/
│   ├── Dockerfile
│   └── sources/
│       ├── 20_pg_cron.sh          # pg_cron aktivieren, Event-Bereinigung planen
│       ├── 30_init_pgbackrest.sh  # pgBackRest Stanza einrichten und prüfen
│       ├── 40_pg_track_settings.sh
│       ├── 50_kvwmapsp.sh         # kvwmapsp-Datenbank und kvwmap-Rolle anlegen
│       ├── pgbackrest.conf        # Basis-Konfiguration (Stanza local, repo1), ins Image gebaut
│       ├── postgresql.conf        # ins Image gebaut UND zur Laufzeit gemountet
│       ├── pg_hba.conf            # ins Image gebaut UND zur Laufzeit gemountet
│       └── .pgpass                # nur zur Laufzeit gemountet
├── data/                          # PostgreSQL-Datendateien (Volume)
├── logs/                          # Logdateien (Volume)
├── pgbackrest/                    # Backup-Daten repo1 (Volume)
├── config/                        # host-spezifisch, nicht in Git (postgresql.conf, pg_hba.conf, .pgpass)
│   └── pgbackrest/                # repo2-Konfiguration, SSH-Key, known_hosts
├── config.example/                # Vorlage für config/pgbackrest/repo2.conf
├── dumps/                         # Dump-Ablage (Volume)
└── docker-compose.yml
```

## Schnellstart

### Voraussetzungen

- Docker und Docker Compose
- Externes Docker-Netzwerk (Standard: `kvwmap_prod`)
- PROJ-Dateien unter `../../volumes/proj/` (proj.db, epsg, MVTR2010.gsb, MVTRS4283.gsb)

### Netzwerk anlegen

```bash
docker network create kvwmap_prod
```

### Umgebungsvariablen setzen

`.env`-Datei im Projektverzeichnis anlegen:

```env
POSTGRES_PASSWORD=geheimes_passwort
POSTGRES_KVWMAP_PASSWORD=kvwmap_passwort
NETWORK_NAME=kvwmap_prod
SERVICE_NAME=pgsql17
```

Auf den GDI-Servern übernimmt das die Rolle `pgsql-container` in
[server-konfig](https://github.com/dudehro/server-konfig) (Clone, `.env`, `config/`, repo2,
Start). Die folgenden Schritte beschreiben die Einrichtung von Hand.

### Verzeichnisse und Log-Cronjob einrichten

Legt die Volume-Verzeichnisse mit korrekter Ownership (uid/gid 999) an und
installiert den Host-Cronjob für die Log-Wartung (`/etc/cron.d/docker-postgis-logs`).
Fehlende Dateien in `config/` werden als Link auf die Vorlagen in `build/sources/` angelegt.
Liest `.env`, muss also **nach** dem Anlegen der `.env` und **vor** dem Start
laufen. Benötigt root (chown + `/etc/cron.d`):

```bash
sudo ./post-clone.sh
```

### Starten

```bash
docker compose up -d
```

## Umgebungsvariablen (Container)

| Variable | Standard | Beschreibung |
|---|---|---|
| `POSTGRES_PASSWORD` | — | Passwort für den `postgres`-Superuser (Pflicht) |
| `INITDB_KVWMAPSP_DB` | `false` | Bei `true`: Datenbank `kvwmapsp` und Rolle `kvwmap` anlegen |
| `INITDB_KVWMAP_PASSWORD` | `kvwmap` | Passwort für die `kvwmap`-Rolle |
| `INITDB_PGBACKREST` | `true` | Bei `false`: pgBackRest-Einrichtung überspringen |
| `INITDB_PGCRON` | `true` | Bei `false`: pg_cron-Einrichtung überspringen |

## InitDB-Skripte

Die Skripte unter `build/sources/` werden beim ersten Start (initdb) in alphabetischer Reihenfolge ausgeführt:

- **`20_pg_cron.sh`** – Aktiviert die `pg_cron`-Erweiterung und plant eine wöchentliche Bereinigung alter Events (samstags 3:30 Uhr).
- **`30_init_pgbackrest.sh`** – Legt die pgBackRest-Stanza `local` in allen konfigurierten Repos an und führt einen ersten Check durch. `stanza-create` wird bis zu 6× wiederholt, weil der asynchrone `archive-push` aus initdb die Sperre kurz halten kann.
- **`40_pg_track_settings.sh`** – Richtet `pg_track_settings` ein.
- **`50_kvwmapsp.sh`** – Legt die Datenbank `kvwmapsp` mit PostGIS, pgcrypto und Monitoring-Schema an. Aktualisiert proj4text für mecklenburgische Koordinatenreferenzsysteme (SRID 4314, 4178, 2398, 31967–31969). Richtet einen `zabbix`-Benutzer für das Monitoring ein.

## pgBackRest

Eine Stanza `local` mit zwei Repos:

| Repo | Ort | Ziel | Retention |
|---|---|---|---|
| repo1 | `/pgbackrest` (lokal) | kurze RTO, wenig Platz | 1 Full, WAL nur ab dem letzten Backup (PITR ~ 1 Tag) |
| repo2 | Tier2 per SFTP, verschlüsselt | lange Aufbewahrung | 2 Full (monatlich), WAL der letzten 14 Backups (PITR ~ 2 Wochen) |

- Die Basis-Konfiguration liegt im Image unter `/etc/pgbackrest/pgbackrest.conf`.
- Host-spezifisches (repo2, SSH-Key, `known_hosts`) liegt in `./config/pgbackrest/` und wird nach `/etc/pgbackrest/host` gemountet (`PGBACKREST_CONFIG_INCLUDE_PATH`).
- Ist das Verzeichnis leer, sichert der Container nur nach repo1.
- Beide Repos verwenden Bundles und Block-Incremental.
- Backups laufen pro Repo: `pgbackrest --stanza=local --repo=1|2 --type=full|incr backup`.
- Die Retention von repo2 geht von **einem Backup nach repo2 pro Tag** aus.

**WAL-Archivierung:**
- `archive-push` schreibt asynchron in beide Repos.
- Ist repo2 nicht erreichbar, bekommt repo1 die WAL weiterhin. PostgreSQL wiederholt die Archivierung, `pg_wal` wächst, und die WAL wird nachgeschoben, sobald repo2 wieder da ist.
- Ab `archive-push-queue-max` (16GiB, pro Host per `PGBACKREST_ARCHIVE_PUSH_QUEUE_MAX` änderbar) verwirft pgBackRest WAL statt die Platte zu füllen. Dann ist bis zum nächsten Backup kein PITR über diese Lücke möglich.
- Überwachen: `pg_stat_archiver.failed_count`.

### repo2 einrichten

Auf den GDI-Servern erledigt das die Rolle `pgsql-container` in server-konfig, einschließlich des SFTP-Users auf dem Storage-Server. Von Hand:

1. Auf dem Storage-Server einen SFTP-User `pgbr-<host>` anlegen (server-konfig, Rolle `pgbackrest-repo`).
2. Die Vorlage `config.example/pgbackrest/repo2.conf` nach `./config/pgbackrest/` kopieren und anpassen:
   - `repo2.conf`: User, Host, Port, Cipher-Passphrase. Die Passphrase zusätzlich in Vaultwarden ablegen, ohne sie ist kein Restore möglich.
   - `id_ed25519`: privater Schlüssel, Rechte 0600.
   - `known_hosts`: Host-Keys des Storage-Servers. **Der ECDSA-Key muss enthalten sein**, weil libssh2 ihn bevorzugt. Mit nur dem ed25519-Key schlägt die Prüfung fehl (`LIBSSH2_KNOWNHOST_CHECK_MISMATCH`). Bei einem Port ungleich 22 lautet der Eintrag `[host]:port`.
   - Alle Dateien gehören 999:999.
3. Bei einem neuen Cluster legt `30_init_pgbackrest.sh` die Stanza in beiden Repos an.
4. Bei einem bestehenden Cluster einmalig `pgbackrest --stanza=local stanza-create` und danach `check` ausführen.

Restore nur aus repo2: `pgbackrest --stanza=local --repo=2 restore`.

### Umstieg von postgis 17-3.5 (bullseye)

Das Basis-Image wechselt von bullseye auf trixie. Bestehende Datenverzeichnisse funktionieren weiter (gleiches PostgreSQL-Major), es sind aber zwei Schritte nötig:

- **Collation:** Die glibc ändert sich von 2.31 auf 2.41. Textindizes mit `de_DE` müssen neu gebaut werden (`REINDEX`), danach pro Datenbank `ALTER DATABASE … REFRESH COLLATION VERSION`.
- **PostGIS 3.5 → 3.6:** in jeder Datenbank mit PostGIS `ALTER EXTENSION postgis UPDATE` ausführen, ebenso für weitere PostGIS-Extensions.

## Log-Wartung

Das Skript `logs.sh` liegt im Image unter `/usr/local/bin/logs.sh` und komprimiert
alte PostgreSQL-Logs mit `zstd` (Dateien älter als 1 Tag) und löscht Logs sowie
Archive nach einer konfigurierbaren Anzahl Tagen (Default 90):

```
logs.sh <Log-Verzeichnis> <Alter-in-Tagen>
```

Ausgeführt wird es im Container (fixer Log-Pfad `/var/log/pgsql`), ausgelöst per
**Host-Cron** via `docker exec`. Der Cronjob wird beim Aufsetzen automatisch von
`post-clone.sh` unter `/etc/cron.d/docker-postgis-logs` eingerichtet:

```cron
# Täglich 03:30: PostgreSQL-Logs im Container komprimieren, nach 90 Tagen löschen
30 3 * * *  root  docker exec kvwmap_prod_pgsql /usr/local/bin/logs.sh /var/log/pgsql 90
```

Der Containername ergibt sich aus `${NETWORK_NAME}_${SERVICE_NAME}` (hier
`kvwmap_prod_pgsql`) und wird von `post-clone.sh` aus der `.env` übernommen;
Zeitplan und Aufbewahrungsdauer sind in der erzeugten Cron-Datei frei anpassbar.

## Monitoring

Das Monitoring-Schema (`monitor`) in der `kvwmapsp`-Datenbank enthält Views und Funktionen für Zabbix:

- `monitor.locked_tables` – Aktuelle Sperren
- `monitor.cache_hit` – Buffer-Cache-Trefferrate
- `monitor.transactions` – Aktive und offene Transaktionen
- `monitor.zabbix_wal_activity` – WAL-Aktivität

Zugriff über den Datenbankbenutzer `zabbix`.

## Volumes

| Host-Pfad | Container-Pfad | Inhalt |
|---|---|---|
| `./data` | `/var/lib/postgresql/data` | Datenbankdateien |
| `./logs` | `/var/log/pgsql` | PostgreSQL-Logs |
| `./pgbackrest` | `/pgbackrest` | Backup-Daten repo1 |
| `./config/pgbackrest` | `/etc/pgbackrest/host` (ro) | repo2-Konfiguration, SSH-Key, known_hosts |
| `./config/.pgpass` | `/var/lib/postgresql/config/.pgpass` (ro) | Passwortdatei |
| `./config/postgresql.conf` | `/var/lib/postgresql/config/postgresql.conf` (ro) | Hauptkonfiguration |
| `./config/pg_hba.conf` | `/var/lib/postgresql/config/pg_hba.conf` (ro) | Authentifizierungskonfiguration |
| `./dumps` | `/dumps` | Dump-Ablage |
| `./www` | `/var/www` | Web-Dateien |
