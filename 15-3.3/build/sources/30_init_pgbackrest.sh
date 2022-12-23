#!/bin/bash
#id
#stat /pgbackrest
pgbackrest --stanza=local --log-level-console=info stanza-create
pgbackrest --stanza=local --log-level-console=info check
