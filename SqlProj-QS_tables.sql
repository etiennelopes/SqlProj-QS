--CREATE DATABASE DBADATABASE
--GO

USE DBADATABASE
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--Table Name: tb_qs_errors
--Author: Etienne Lopes
--Description: holds errors found in procs execution
DROP TABLE IF EXISTS dbo.tb_qs_errors
GO
CREATE TABLE dbo.tb_qs_errors
(
	error_num int NOT NULL,
	error_msg nvarchar(4000) NULL,
	error_proc sysname NULL,
	error_date datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET())
)

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--Table Name: tb_qs_db_config_state
--Author: Etienne Lopes
--Description: holds configuration data from every database where is_query_store_on = 1 in the instance.
DROP TABLE IF EXISTS dbo.tb_qs_db_config_state
GO
CREATE TABLE dbo.tb_qs_db_config_state 
(
	Config_ID int IDENTITY(1,1) NOT NULL PRIMARY KEY NONCLUSTERED,
	database_id int NOT NULL,
	database_name sysname NOT NULL,
	desired_state_desc	nvarchar (120) NULL,
	actual_state_desc	nvarchar (120) NULL,
	readonly_reason	int NULL,
	current_storage_size_mb	bigint NULL,
	max_storage_size_mb	bigint NULL,
	flush_interval_seconds	bigint NULL,
	interval_length_minutes	bigint NULL,
	stale_query_threshold_days	bigint NULL,
	max_plans_per_query	bigint NULL,
	query_capture_mode_desc	nvarchar (120) NULL,
	size_based_cleanup_mode_desc nvarchar (120) NULL,
	collected_config_date datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET())
)

CREATE CLUSTERED INDEX ix_tb_qs_db_config_state_database_id ON tb_qs_db_config_state (database_id)
CREATE INDEX ix_tb_qs_db_config_state_collected_config_date ON tb_qs_db_config_state (collected_config_date)

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--Table Name: tb_qs_db_lost_objects
--Author: Etienne Lopes
--Description: holds information about objects (for example SPs) that were dropped and are still referenced by query store for every database where is_query_store_on = 1 in the instance.
DROP TABLE IF EXISTS dbo.tb_qs_db_lost_objects
GO
CREATE TABLE dbo.tb_qs_db_lost_objects 
(
	lost_objects_ID int IDENTITY(1,1) NOT NULL PRIMARY KEY NONCLUSTERED,
	database_id int NOT NULL,
	database_name sysname NOT NULL,
	query_id bigint NULL, 
	lost_object_id bigint NULL, 
	lost_object_sql_text nvarchar(max) NULL, 
	collected_config_date datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET())
)