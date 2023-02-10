#!/bin/bash
#id
#stat /pgbackrest
echo "pgbackrest einrichten und testen"
pgbackrest --stanza=local --log-level-console=info stanza-create
pgbackrest --stanza=local --log-level-console=info check
