#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
     -v conninfo="host=$PRIMARY_HOST port=5432 dbname=$POSTGRES_DB user=$REPLICATION_USER password=$REPLICATION_PASSWORD" <<'EOSQL'
CREATE SUBSCRIPTION t1_sub CONNECTION :'conninfo' PUBLICATION t1_pub;
EOSQL
