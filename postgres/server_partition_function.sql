CREATE OR REPLACE FUNCTION
myschema.server_partition_function()
RETURNS TRIGGER AS
$BODY$
DECLARE
_new_time int;
_tablename text;
_startdate text;
_enddate text;
_result record;
BEGIN
--Takes the current inbound "time" value and determines when midnight is for the given date
_new_time := ((NEW."time"/86400)::int)*86400;
_startdate := to_char(to_timestamp(_new_time), 'YYYY-MM-DD');
_tablename := 'server_'||_startdate;

-- Check if the partition needed for the current record exists
PERFORM 1
FROM   pg_catalog.pg_class c
JOIN   pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE  c.relkind = 'r'
AND    c.relname = _tablename
AND    n.nspname = 'myschema';

-- If the partition needed does not yet exist, then we create it:
-- Note that || is string concatenation (joining two strings to make one)
IF NOT FOUND THEN
_enddate:=_startdate::timestamp + INTERVAL '1 day';
EXECUTE 'CREATE TABLE myschema.' || quote_ident(_tablename) || ' (
CHECK ( "time" >= EXTRACT(EPOCH FROM DATE ' || quote_literal(_startdate) || ')
AND "time" < EXTRACT(EPOCH FROM DATE ' || quote_literal(_enddate) || ')
)
) INHERITS (myschema.server_master)';

-- Table permissions are not inherited from the parent.
-- If permissions change on the master be sure to change them on the child also.
EXECUTE 'ALTER TABLE myschema.' || quote_ident(_tablename) || ' OWNER TO postgres';
EXECUTE 'GRANT ALL ON TABLE myschema.' || quote_ident(_tablename) || ' TO my_role';

-- Indexes are defined per child, so we assign a default index that uses the partition columns
EXECUTE 'CREATE INDEX ' || quote_ident(_tablename||'_indx1') || ' ON myschema.' || quote_ident(_tablename) || ' (time, id)';
END IF;

-- Insert the current record into the correct partition, which we are sure will now exist.
EXECUTE 'INSERT INTO myschema.' || quote_ident(_tablename) || ' VALUES ($1.*)' USING NEW;
RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql;
