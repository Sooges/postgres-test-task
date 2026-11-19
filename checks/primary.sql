\pset pager off

\echo '1. Партиції таблиці t1'
SELECT c.relname AS partition,
       pg_get_expr(c.relpartbound, c.oid) AS bounds,
       (SELECT count(*) FROM t1 AS t WHERE t.tableoid = c.oid) AS rows
FROM pg_inherits AS i
JOIN pg_class AS c ON c.oid = i.inhrelid
WHERE i.inhparent = 't1'::regclass
ORDER BY c.relname;

\echo '2. Згенеровані дані'
SELECT count(*) AS total_rows,
       min(op_date) AS min_date,
       max(op_date) AS max_date,
       count(DISTINCT message ->> 'client_id') AS clients
FROM t1;

\echo '3. Унікальність operation_guid (повторна вставка має завершитись помилкою)'
BEGIN;
INSERT INTO t1 (amount, operation_guid, message)
SELECT amount, operation_guid, message FROM t1 ORDER BY id LIMIT 1;
ROLLBACK;

SELECT count(*) AS rows, count(DISTINCT operation_guid) AS distinct_guids FROM t1;

\echo '4-5. Регламентні завдання'
SELECT jobname, schedule, command, active FROM cron.job ORDER BY jobid;

SELECT j.jobname, d.status, count(*) AS runs, max(d.end_time) AS last_run
FROM cron.job_run_details AS d
JOIN cron.job AS j USING (jobid)
GROUP BY j.jobname, d.status
ORDER BY j.jobname, d.status;

SELECT state, count(*) AS rows FROM t1 GROUP BY state ORDER BY state;

SELECT id, op_date, amount, state, operation_guid, message
FROM t1
ORDER BY id DESC
LIMIT 5;

\echo '5. Парність секунд і парність id (зміни відкочуються)'
BEGIN;
INSERT INTO t1 (amount, state, message)
SELECT t1_random_amount(), 0, t1_random_message() FROM generate_series(1, 4);
CALL t1_confirm_operations();
SELECT floor(extract(second FROM clock_timestamp()))::integer % 2 AS seconds_parity,
       id,
       id % 2 AS id_parity,
       state
FROM t1
ORDER BY id DESC
LIMIT 4;
ROLLBACK;

\echo '6. Матеріалізоване представлення проти прямого підрахунку'
SELECT (SELECT sum(amount) FROM t1 WHERE state = 1) AS table_total,
       (SELECT sum(total_amount) FROM t1_client_totals) AS view_total,
       (SELECT count(*) FROM t1_client_totals) AS view_rows;

SELECT * FROM t1_client_totals ORDER BY client_id, op_type LIMIT 6;

\echo '7. Публікація та стан реплікації'
SELECT p.pubname, p.pubviaroot, t.tablename
FROM pg_publication AS p
JOIN pg_publication_tables AS t USING (pubname);

SELECT application_name, state, sent_lsn, replay_lsn, replay_lag
FROM pg_stat_replication;
