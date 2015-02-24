-- Find where is a SQL Server instance a database object is located, the examples below will help you
-- discover where the object named 'sp_delete_backuphistory' is defined and what it's definition is.


EXEC sp_msforeachdb 
'if exists(select 1 from [?].sys.objects where name=''sp_delete_backuphistory'')
select ''?'' as FoundInDb from [?].sys.objects where name=''sp_delete_backuphistory'''


--Line by line definition of the object (Used for SQL Server 2005 - 2008R2)
EXEC sp_helptext N'msdb.dbo.sp_delete_backuphistory';

--Single column of the object (Used for SQL Server 2005 - 2014)
SELECT OBJECT_DEFINITION (OBJECT_ID(N'msdb.dbo.sp_delete_backuphistory'));

--Can use to comepare one or more objects / single column definition (Used for SQL Server 2005 - 2014)
SELECT definition
FROM sys.sql_modules
WHERE object_id = (OBJECT_ID(N'msdb.dbo.sp_delete_backuphistory'));
