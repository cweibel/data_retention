USE [DBA]
GO

/*
This table is to display the disk OS sees.  
Tracking this information will give us history on
file system changes and growth.
*/



/****** Object:  Table [dbo].[Server_disk]    Script Date: 04/10/2014 10:17:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[DB_Statistics_Server_disk](
	[run_date] [datetime] NULL,
	[volume_mount_point] [char](5) NULL,
	[total_bytes] [bigint] NULL,
	[available_bytes] [bigint] NULL
) ON [PRIMARY] WITH (DATA_COMPRESSION = PAGE)

GO

SET ANSI_PADDING OFF
GO


