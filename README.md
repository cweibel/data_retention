# Data Retention - SQL Server and PostgreSQL

There are two main folder:
 * postgres - Contains the scripts mentioned in the presentation to create and maintain table partitions in PostgreSQL
 * sql_server - Contains the maintenance scripts mentioned by Joe in the presentation for SQL Server.

## SQL Server

### Break/Fix

There are two scripts in the 'Truncate_msdb_history' folder.  The first is purge_backup_jobhist_msdb.sql which accepts a datatime parameter, any information about backups before this date will be deleted from the MSBD database.  Use this script to triage (delete with prejudice) old information about backups.

The second script is runcate_msdb_history.sql, this one can be scheduled to run weekly in SQL Agent and will keep the last two years worth of backup history.

### Maintenance

The 'IndexReorg - Daily.sql' file should be scheduled in SQL Agent to run daily.  It will automatically determine which indexes need to be rebuilt versus simply reorganized based on the average fragmentation levels.

The 'cycle_error_logs.sql' file should be scheduled weekly in SQL Agent to rotate the SQL Server Error Logs which accumulate errors from various components of SQL Server such as the agent, database engine, and reporting services.

### Discovery

There are several scripts included which can gather information about your databases and instances.

The first is 'FindSqlObject_view_Definition.sql' **<<Joe, what the heck is this one doing??...

In the DBA_Data_Statistics folder there are additional scripts to get a peek at your databases:
 * create_job_DBA_Statistics.sql - database, files, latency, reads, writes and other physical statistics
 * create_proc_usp_DatabaseSizing_insert.sql - database files current and max sizes, available space, physical file name, inserts these values into tables created by the following queries:
   * create_tbl_DB_Details.sql -
   * create_tbl_DB_Statistics_DB_Size_Details.sql -
   * create_tbl_DB_Statistics_DB_Size_Sum.sql -
   * create_tbl_Server_Disk.sql -
   * create_tble_DB_Statistics_DB_Size_Detail.sql


## PostgreSQL Table Partitioning

There is a particular order to run the sample install.  We will assume you have PostgreSQL installed and have a schema called "myschema" already created.

 * Create the Master Table
 * Create the Server Partition Function
 * Create a Trigger on the Master Table
 * Install PLSH and Create Partition Maintenance Function

### Create the Master Table

This one is pretty simple, just run create_server_master.sql, for your own real life example you would add your appropriate columns, just make sure that one of them is named "time" of datatype int.

### Create the Server Partition Function

From this function you can control the amount of time represented by each child, in this example 86400 seconds (one day).  There are a few notes in this script (server_partition_function.sql) about table permissions and indexes you should create on each new child table since they are not inherited from the parent.

### Create a Trigger on the Master Table

Just run create_trigger.sql


### Install PLSH and Create Partition Maintenance Function

The partition_maintenance function writes out the old child tables to the filesystem.  This function uses PLSH which is a PostgreSQL extension which needs to be compiled into the database.  If you just want to drop the tables and skip exporting old child tables, this step can be skipped.

```bash
mkdir -p /db/partition_dump #Create the output folder the child tables will be written to
chown postgres:postgres /db/partition_dump
cd /usr/local/src # Build the extension .so files for postgresql
curl -L href="https://github.com/petere/plsh/archive/9a429a4bb9ed98e80d12a931f90458a712d0adbd.tar.gz">https://github.com/petere/plsh/archive/9a429a4bb9ed98e80d12a931f90458a712d0adbd.tar.gz -o plsh.tar.gz
tar zxf plsh.tar.gz
cd plsh-*/
make all install # Note that the postgres header files must be available
psql my_database  # Substitute the name of your database with the partitioned tables
```

Now for each database run:
```
my_database> CREATE EXTENSION plsh; # NOTE: This must be done once for each database
```

Now you can run the partition_maintenance.sql file to create the partition maintenance function.
