# docker-postgis

PostgreSQL 16 / PostGIS 3.5 Docker-Image mit zusätzlichen Erweiterungen und vorkonfigurierter Umgebung für den Einsatz mit [kvwmap](https://github.com/kvwmap/kvwmap).

Basiert auf dem offiziellen Image [`postgis/postgis:16-3.5`](https://hub.docker.com/r/postgis/postgis).

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
- **WAL-Archivierung:** aktiviert via pgBackRest (`pgbackrest --stanza local archive-push`)
- **PGTune-Profil:** Web-Workload, 64 GB RAM, 24 CPUs, SSD (als Vorlage in `config/postgresql.conf` hinterlegt)

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
│       ├── pgbackrest.local.conf
│       ├── postgresql.conf
│       └── pg_hba.conf
├── config/
│   ├── postgresql.conf            # zur Laufzeit eingebundene Konfiguration
│   ├── pg_hba.conf
│   └── .pgpass
├── data/                          # PostgreSQL-Datendateien (Volume)
├── logs/                          # Logdateien (Volume)
├── pgbackrest/                    # Backup-Daten (Volume)
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
SERVICE_NAME=pgsql16
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
- **`30_init_pgbackrest.sh`** – Legt die pgBackRest-Stanza `local` an und führt einen ersten Check durch.
- **`40_pg_track_settings.sh`** – Richtet `pg_track_settings` ein.
- **`50_kvwmapsp.sh`** – Legt die Datenbank `kvwmapsp` mit PostGIS, pgcrypto und Monitoring-Schema an. Aktualisiert proj4text für mecklenburgische Koordinatenreferenzsysteme (SRID 4314, 4178, 2398, 31967–31969). Richtet einen `zabbix`-Benutzer für das Monitoring ein.

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
| `./pgbackrest` | `/pgbackrest` | Backup-Daten |
| `./config/.pgpass` | `/var/lib/postgresql/config/.pgpass` | Passwortdatei |
| `./config/postgresql.conf` | `/var/lib/postgresql/config/postgresql.conf` | Hauptkonfiguration |
| `./config/pg_hba.conf` | `/var/lib/postgresql/config/pg_hba.conf` | Authentifizierungskonfiguration |
| `./dumps` | `/dumps` | Dump-Ablage |
| `./www` | `/var/www` | Web-Dateien |
