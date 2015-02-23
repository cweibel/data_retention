USE [msdb]
GO

/*
Job and schedule for database statistics needed for trending information.
*/



/****** Object:  Job [DBA_Data_Statistics]    Script Date: 04/10/2014 10:31:58 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 04/10/2014 10:31:58 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA_Data_Statistics',
		@enabled=1,
		@notify_level_eventlog=0,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N'database details listing read/writes/ read&write waits',
		@category_name=N'Database Maintenance',
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DB Details io wait ms]    Script Date: 04/10/2014 10:31:58 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DB Details io wait ms',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=3,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'SELECT f.database_id, DB_NAME(f.database_id) AS database_name, f.name AS logical_file_name, f.[file_id], f.type_desc,
	CAST (CASE
		-- Handle UNC paths (e.g. ''\\fileserver\readonlydbs\dept_dw.ndf'')
		WHEN LEFT (LTRIM (f.physical_name), 2) = ''\\''
			THEN LEFT (LTRIM (f.physical_name),CHARINDEX(''\'',LTRIM(f.physical_name),CHARINDEX(''\'',LTRIM(f.physical_name), 3) + 1) - 1)
			-- Handle local paths (e.g. ''C:\Program Files\...\master.mdf'')
			WHEN CHARINDEX(''\'', LTRIM(f.physical_name), 3) > 0
			THEN UPPER(LEFT(LTRIM(f.physical_name), CHARINDEX (''\'', LTRIM(f.physical_name), 3) - 1))
		ELSE f.physical_name
	END AS NVARCHAR(255)) AS logical_disk,
	fs.size_on_disk_bytes/1024/1024 AS size_on_disk_Mbytes,
	fs.num_of_reads, fs.num_of_writes,
	fs.num_of_bytes_read/1024/1024 AS num_of_Mbytes_read,
	fs.num_of_bytes_written/1024/1024 AS num_of_Mbytes_written,
	fs.io_stall/1000/60 AS io_stall_min,
	fs.io_stall_read_ms/1000/60 AS io_stall_read_min,
	fs.io_stall_write_ms/1000/60 AS io_stall_write_min,
	(fs.io_stall_read_ms / (1.0 + fs.num_of_reads)) AS avg_read_latency_ms,
	(fs.io_stall_write_ms / (1.0 + fs.num_of_writes)) AS avg_write_latency_ms,
	((fs.io_stall_read_ms/1000/60)*100)/(CASE WHEN fs.io_stall/1000/60 = 0 THEN 1 ELSE fs.io_stall/1000/60 END) AS io_stall_read_pct,
	((fs.io_stall_write_ms/1000/60)*100)/(CASE WHEN fs.io_stall/1000/60 = 0 THEN 1 ELSE fs.io_stall/1000/60 END) AS io_stall_write_pct,
	ABS((sample_ms/1000)/60/60) AS ''sample_HH'',
	((fs.io_stall/1000/60)*100)/(ABS((sample_ms/1000)/60))AS ''io_stall_pct_of_overall_sample'' --Number of milliseconds since the computer was started.
INTO #db_details
FROM sys.dm_io_virtual_file_stats (default, default) AS fs
INNER JOIN sys.master_files AS f ON fs.database_id = f.database_id AND fs.[file_id] = f.[file_id]



INSERT INTO dba..DB_Statistics_DB_Details
([run_date],
 [database_id],
 [database_name],
 [logical_file_name],
 [file_id],
 [type_desc],
 [logical_disk],
 [size_on_disk_Mbytes],
 [num_of_reads],
 [num_of_writes],
 [num_of_Mbytes_read],
 [num_of_Mbytes_written],
 [io_stall_min],
 [io_stall_read_min],
 [io_stall_write_min],
 [avg_read_latency_ms],
 [avg_write_latency_ms],
 [io_stall_read_pct],
 [io_stall_write_pct],
 [sample_HH],
 [io_stall_pct_of_overall_sample]
 )
 SELECT GETDATE(),
 [database_id],
 [database_name],
 [logical_file_name],
 [file_id],
 [type_desc],
 [logical_disk],
 [size_on_disk_Mbytes],
 [num_of_reads],
 [num_of_writes],
 [num_of_Mbytes_read],
 [num_of_Mbytes_written],
 [io_stall_min],
 [io_stall_read_min],
 [io_stall_write_min],
 [avg_read_latency_ms],
 [avg_write_latency_ms],
 [io_stall_read_pct],
 [io_stall_write_pct],
 [sample_HH],
 [io_stall_pct_of_overall_sample]
 FROM #db_details


DROP TABLE #db_details',
		@database_name=N'master',
		@flags=20
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Server disk]    Script Date: 04/10/2014 10:31:58 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Server disk',
		@step_id=2,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=3,
		@on_fail_action=4,
		@on_fail_step_id=3,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'DECLARE @server_disk TABLE
(
   [volume_mount_point] CHAR(5),
   [total_bytes] int,
   [available_bytes] int
)
go

WITH os_volume_stats as
(
	select f.database_id, f.file_id, volume_mount_point, total_bytes, available_bytes, total_bytes/1024/1024/1024 AS [total gig], available_bytes/1024/1024/1024 AS [available gig]
	from sys.master_files as f
	cross apply sys.dm_os_volume_stats(f.database_id, f.file_id)
)
INSERT INTO dba..DB_Statistics_Server_disk
select DISTINCT GETDATE(), s.volume_mount_point,  total_bytes, available_bytes
from os_volume_stats s join sys.databases d on s.database_id = d.database_id
',
		@database_name=N'master',
		@flags=20
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Database file Sizing]    Script Date: 04/10/2014 10:31:58 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Database file Sizing',
		@step_id=3,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'EXECUTE dba.dbo.usp_DatabaseSizing_insert @Granularity = NULL , @Database_Name = NULL

EXECUTE dba.dbo.usp_DatabaseSizing_insert @Granularity = ''Database'' , @Database_Name = NULL',
		@database_name=N'DBA',
		@flags=20
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Sunday-Noon',
		@enabled=1,
		@freq_type=8,
		@freq_interval=1,
		@freq_subday_type=1,
		@freq_subday_interval=0,
		@freq_relative_interval=0,
		@freq_recurrence_factor=1,
		@active_start_date=20140405,
		@active_end_date=99991231,
		@active_start_time=120000,
		@active_end_time=235959,
		@schedule_uid=N'de9b7306-2850-46b0-a8dc-bcda8f3737d2'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Wednesday - Midnight',
		@enabled=1,
		@freq_type=8,
		@freq_interval=8,
		@freq_subday_type=1,
		@freq_subday_interval=0,
		@freq_relative_interval=0,
		@freq_recurrence_factor=1,
		@active_start_date=20140406,
		@active_end_date=99991231,
		@active_start_time=0,
		@active_end_time=235959,
		@schedule_uid=N'30394d38-e629-4180-a500-cd763e572247'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
