#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
     -v repl_user="$REPLICATION_USER" -v repl_password="$REPLICATION_PASSWORD" <<'EOSQL'
CREATE ROLE :"repl_user" WITH LOGIN REPLICATION PASSWORD :'repl_password';
GRANT SELECT ON t1 TO :"repl_user";
CREATE PUBLICATION t1_pub FOR TABLE t1 WITH (publish_via_partition_root = true);
EOSQL
