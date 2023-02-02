#!/bin/bash
#id
#stat /pgbackrest
echo "pgbackrest einrichten und testen"
sudo -u postgres pgbackrest --stanza=local --log-level-console=info stanza-create
sudo -u postgres pgbackrest --stanza=local --log-level-console=info check
