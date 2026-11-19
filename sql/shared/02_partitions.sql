CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT t1_ensure_partitions(
    (current_date - interval '4 months')::date,
    (current_date + interval '2 months')::date
);

SELECT cron.schedule(
    't1-partitions',
    '0 0 * * *',
    $$SELECT t1_ensure_partitions(current_date, (current_date + interval '2 months')::date)$$
);

SELECT cron.schedule(
    'cron-history-cleanup',
    '0 * * * *',
    $$DELETE FROM cron.job_run_details WHERE end_time < now() - interval '1 day'$$
);
