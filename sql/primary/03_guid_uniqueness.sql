CREATE TABLE t1_operation_guid (
    operation_guid uuid PRIMARY KEY
);

CREATE FUNCTION t1_operation_guid_sync()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO t1_operation_guid (operation_guid) VALUES (NEW.operation_guid);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.operation_guid IS DISTINCT FROM OLD.operation_guid THEN
            UPDATE t1_operation_guid
               SET operation_guid = NEW.operation_guid
             WHERE operation_guid = OLD.operation_guid;
        END IF;
        RETURN NEW;
    ELSE
        DELETE FROM t1_operation_guid WHERE operation_guid = OLD.operation_guid;
        RETURN OLD;
    END IF;
END;
$$;

CREATE TRIGGER t1_operation_guid_insert
    BEFORE INSERT ON t1
    FOR EACH ROW
    EXECUTE FUNCTION t1_operation_guid_sync();

CREATE TRIGGER t1_operation_guid_update
    BEFORE UPDATE OF operation_guid ON t1
    FOR EACH ROW
    EXECUTE FUNCTION t1_operation_guid_sync();

CREATE TRIGGER t1_operation_guid_delete
    BEFORE DELETE ON t1
    FOR EACH ROW
    EXECUTE FUNCTION t1_operation_guid_sync();
