CREATE FUNCTION t1_random_message()
RETURNS jsonb
LANGUAGE sql
VOLATILE
AS $$
    SELECT jsonb_build_object(
        'account', 'UA' || lpad((c.client_id % 90 + 10)::text, 2, '0') || '305299'
                   || lpad((c.client_id * 10 + c.account_no)::text, 19, '0'),
        'client_id', c.client_id,
        'op_type', c.op_type
    )
    FROM (
        SELECT
            1 + floor(random() * 1000)::integer                       AS client_id,
            1 + floor(random() * 3)::integer                          AS account_no,
            CASE WHEN random() < 0.7 THEN 'online' ELSE 'offline' END AS op_type
    ) AS c;
$$;

CREATE FUNCTION t1_random_amount()
RETURNS numeric
LANGUAGE sql
VOLATILE
AS $$
    SELECT round((0.01 + random() * 49999.99)::numeric, 2);
$$;

CREATE PROCEDURE t1_generate(p_rows integer DEFAULT 120000, p_months integer DEFAULT 4)
LANGUAGE plpgsql
AS $$
DECLARE
    v_to   timestamptz := now();
    v_from timestamptz := v_to - make_interval(months => p_months);
BEGIN
    PERFORM t1_ensure_partitions(
        (v_from AT TIME ZONE 'UTC')::date,
        (v_to AT TIME ZONE 'UTC')::date
    );

    INSERT INTO t1 (op_date, amount, state, message)
    SELECT s.op_date, t1_random_amount(), 1, t1_random_message()
    FROM (
        SELECT v_from + random() * (v_to - v_from) AS op_date
        FROM generate_series(1, p_rows)
    ) AS s
    ORDER BY s.op_date;
END;
$$;

CALL t1_generate();

ANALYZE t1;
