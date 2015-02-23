-- Find where is a SQL Server instance a database object is located

EXEC sp_msforeachdb 
'if exists(select 1 from [?].sys.objects where name=''sp_delete_backuphistory'')
select ''?'' as FoundInDb from [?].sys.objects where name=''sp_delete_backuphistory'''


--Line by line definition of the object
EXEC sp_helptext N'msdb.dbo.sp_delete_backuphistory';

--Single column of the object
SELECT OBJECT_DEFINITION (OBJECT_ID(N'msdb.dbo.sp_delete_backuphistory'));

--can use to comepare one or more ojbects / single column definition
SELECT definition
FROM sys.sql_modules
WHERE object_id = (OBJECT_ID(N'msdb.dbo.sp_delete_backuphistory'));
