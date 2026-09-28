-- Frappe Sync - PostgreSQL Trigger Setup
-- Run ONCE on your database as superuser

CREATE OR REPLACE FUNCTION frappe_sync_notify()
RETURNS trigger AS $$
BEGIN
    PERFORM pg_notify('frappe_sync_new_row', NEW.id::text);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS frappe_sync_trigger ON access_log;

CREATE TRIGGER frappe_sync_trigger
AFTER INSERT ON access_log
FOR EACH ROW
EXECUTE FUNCTION frappe_sync_notify();
