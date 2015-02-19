CREATE TRIGGER server_master_trigger
BEFORE INSERT ON myschema.server_master
FOR EACH ROW EXECUTE PROCEDURE myschema.server_partition_function();
