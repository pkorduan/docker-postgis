#!/bin/bash
set -e

if [ "${INITDB_PGBACKREST:-true}" = "true" ]; then
    echo "Einrichten und Testen von pgbackrest..."
    # Mit archive-async kann der Hintergrund-Prozess von archive-push (WAL aus initdb) noch die Sperre halten,
    # die stanza-create braucht -> ein paar Mal wiederholen
    for i in 1 2 3 4 5 6; do
        pgbackrest --stanza=local --log-level-console=info stanza-create && break
        [ "$i" -eq 6 ] && exit 1
        echo "stanza-create fehlgeschlagen, neuer Versuch in 10s ($i/6)"
        sleep 10
    done
    pgbackrest --stanza=local --log-level-console=info check
else
    echo "pgBackrest-Einrichtung übersprungen (INITDB_PGBACKREST=$INITDB_PGBACKREST)"
fi
