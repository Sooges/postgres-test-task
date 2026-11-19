\pset pager off

\echo '7. Підписка'
SELECT s.subname, s.subenabled, r.srrelid::regclass AS table_name, r.srsubstate AS sync_state
FROM pg_subscription AS s
JOIN pg_subscription_rel AS r ON r.srsubid = s.oid;

SELECT subname, received_lsn, latest_end_time FROM pg_stat_subscription WHERE relid IS NULL;

\echo '7. Дані на репліці'
SELECT state, count(*) AS rows FROM t1 GROUP BY state ORDER BY state;

SELECT id, op_date, amount, state, operation_guid, message
FROM t1
ORDER BY id DESC
LIMIT 5;
