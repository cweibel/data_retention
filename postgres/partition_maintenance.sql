CREATE OR REPLACE FUNCTION
myschema.partition_maintenance(in_tablename_prefix text, in_master_tablename text, in_asof date)
RETURNS text AS
$BODY$
DECLARE
_result record;
_current_time_without_special_characters text;
_out_filename text;
_return_message text;
return_message text;
BEGIN
-- Get the current date in YYYYMMDD_HHMMSS.ssssss format
_current_time_without_special_characters :=
REPLACE(REPLACE(REPLACE(NOW()::TIMESTAMP WITHOUT TIME ZONE::TEXT, '-', ''), ':', ''), ' ', '_');

-- Initialize the return_message to empty to indicate no errors hit
_return_message := '';

--Validate input to function
IF in_tablename_prefix IS NULL THEN
RETURN 'Child table name prefix must be provided'::text;
ELSIF in_master_tablename IS NULL THEN
RETURN 'Master table name must be provided'::text;
ELSIF in_asof IS NULL THEN
RETURN 'You must provide the as-of date, NOW() is the typical value';
END IF;

FOR _result IN SELECT * FROM pg_tables WHERE schemaname='myschema' LOOP

IF POSITION(in_tablename_prefix in _result.tablename) > 0 AND char_length(substring(_result.tablename from '[0-9-]*$')) <> 0 AND (in_asof - interval '15 days') > to_timestamp(substring(_result.tablename from '[0-9-]*$'),'YYYY-MM-DD') THEN

_out_filename := '/db/partition_dump/' || _result.tablename || '_' || _current_time_without_special_characters || '.sql.gz';
BEGIN
-- Call function export_partition(child_table text) to export the file
PERFORM myschema.export_partition(_result.tablename::text, _out_filename::text);
-- If the export was successful drop the child partition
EXECUTE 'DROP TABLE myschema.' || quote_ident(_result.tablename);
_return_message := return_message || 'Dumped table: ' || _result.tablename::text || ', ';
RAISE NOTICE 'Dumped table %', _result.tablename::text;
EXCEPTION WHEN OTHERS THEN
_return_message := return_message || 'ERROR dumping table: ' || _result.tablename::text || ', ';
RAISE NOTICE 'ERROR DUMPING %', _result.tablename::text;
END;
END IF;
END LOOP;

RETURN _return_message || 'Done'::text;
END;
$BODY$
LANGUAGE plpgsql VOLATILE COST 100;

ALTER FUNCTION myschema.partition_maintenance(text, text, date) OWNER TO postgres;

GRANT EXECUTE ON FUNCTION myschema.partition_maintenance(text, text, date) TO postgres;
GRANT EXECUTE ON FUNCTION myschema.partition_maintenance(text, text, date) TO my_role;

The function below is again generic and allows you to pass in the table name of the file you would like to export to the operating system and the name of the compressed file that will contain the exported table.

-- Helper Function for partition maintenance
CREATE OR REPLACE FUNCTION myschema.export_partition(text, text) RETURNS text AS
$BASH$
#!/bin/bash
tablename=${1}
filename=${2}
# NOTE: pg_dump must be available in the path.
pg_dump -U postgres -t myschema."${tablename}" my_database| gzip -c > ${filename} ;
$BASH$
LANGUAGE plsh;

ALTER FUNCTION myschema.export_partition(text, text) OWNER TO postgres;

GRANT EXECUTE ON FUNCTION myschema.export_partition(text, text) TO postgres;
GRANT EXECUTE ON FUNCTION myschema.export_partition(text, text) TO my_role;
