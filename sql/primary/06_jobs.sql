CREATE PROCEDURE t1_add_operation()
LANGUAGE sql
AS $$
    INSERT INTO t1 (amount, state, message)
    VALUES (t1_random_amount(), 0, t1_random_message());
$$;

CREATE PROCEDURE t1_confirm_operations()
LANGUAGE plpgsql
AS $$
DECLARE
    v_parity integer := floor(extract(second FROM clock_timestamp()))::integer % 2;
BEGIN
    UPDATE t1
       SET state = 1
     WHERE state = 0
       AND id % 2 = v_parity;
END;
$$;

SELECT cron.schedule('t1-add-operation', '5 seconds', 'CALL t1_add_operation()');

SELECT cron.schedule('t1-confirm-operations', '3 seconds', 'CALL t1_confirm_operations()');
