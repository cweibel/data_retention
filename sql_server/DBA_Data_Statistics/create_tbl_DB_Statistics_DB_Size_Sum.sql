USE [DBA]
GO

/*
Summary of database size to look at for 
trending information of growth.
*/



/****** Object:  Table [dbo].[Database_Size_Sum]    Script Date: 04/10/2014 10:22:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[DB_Statistics_DB_Size_Sum](
	[run_date] [datetime] NULL,
	[Database Name] [varchar](100) NULL,
	[DB Size (Mb)] [bigint] NOT NULL,
	[DB Free (Mb)] [bigint] NOT NULL,
	[DB Used (Mb)] [bigint] NOT NULL,
	[Data Size (Mb)] [bigint] NOT NULL,
	[Data Free (Mb)] [numeric](18, 2) NOT NULL,
	[Data Used (Mb)] [numeric](18, 2) NOT NULL,
	[Data Free %] [decimal](18, 2) NULL,
	[Log Size (Mb)] [bigint] NULL,
	[Log Free (Mb)] [bigint] NULL,
	[Log Used (Mb)] [bigint] NULL,
	[Log Free %] [decimal](18, 2) NULL
) ON [PRIMARY] WITH (DATA_COMPRESSION = PAGE)

GO

SET ANSI_PADDING OFF
GO


