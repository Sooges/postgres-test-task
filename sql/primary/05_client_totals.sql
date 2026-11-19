CREATE MATERIALIZED VIEW t1_client_totals AS
SELECT
    (message ->> 'client_id')::bigint AS client_id,
    message ->> 'op_type'             AS op_type,
    sum(amount)                       AS total_amount
FROM t1
WHERE state = 1
GROUP BY 1, 2;

CREATE UNIQUE INDEX t1_client_totals_pkey ON t1_client_totals (client_id, op_type);

CREATE FUNCTION t1_refresh_client_totals()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM old_rows AS o
        JOIN new_rows AS n USING (id)
        WHERE o.state = 0 AND n.state = 1
    ) THEN
        PERFORM pg_advisory_xact_lock(hashtext('t1_client_totals'));
        REFRESH MATERIALIZED VIEW CONCURRENTLY t1_client_totals;
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER t1_state_confirmed
    AFTER UPDATE ON t1
    REFERENCING OLD TABLE AS old_rows NEW TABLE AS new_rows
    FOR EACH STATEMENT
    EXECUTE FUNCTION t1_refresh_client_totals();
