USE master

--Proc Name: sp_get_qs_db_config_state
--Author: Etienne Lopes
--Description: Shows current configuration data from every database where is_query_store_on = 1 in the instance. 
--		Notes: 
--			1 - This stored procedure must be created on master database;
--			2 - The results are sent to the std output and (unlike the other version) they're not persisted. 
DROP PROCEDURE IF EXISTS sp_get_qs_db_config_state
GO
CREATE PROC sp_get_qs_db_config_state
AS
	BEGIN TRY
		DECLARE @i int = 1, @MaxID int, @stmt nvarchar(max)
		DECLARE @database_id int, @database_name sysname

		SELECT IDENTITY(int,1,1) AS ID, database_id, name
		INTO #tmp
		FROM sys.databases
		WHERE is_query_store_on = 1

		CREATE TABLE #tb_qs_db_config_state 
		(
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

		SELECT @stmt = ''
		SELECT @MaxID = MAX(ID) FROM #tmp
		WHILE @i <= @MaxID
		BEGIN
			SELECT @database_id = database_id, @database_name = name 
			FROM #tmp WHERE ID = @i
	
			SELECT @stmt += '
			USE ' + @database_name + '
			INSERT INTO #tb_qs_db_config_state
			(
				database_id, database_name,
				desired_state_desc, actual_state_desc, readonly_reason, current_storage_size_mb,
				max_storage_size_mb, flush_interval_seconds, interval_length_minutes,
				stale_query_threshold_days, max_plans_per_query, query_capture_mode_desc,
				size_based_cleanup_mode_desc
			)
			SELECT ' + CAST(@database_id AS nvarchar) + ', ''' + @database_name + ''',' + '
				desired_state_desc, actual_state_desc, readonly_reason, current_storage_size_mb,
				max_storage_size_mb, flush_interval_seconds, interval_length_minutes,
				stale_query_threshold_days, max_plans_per_query, query_capture_mode_desc,
				size_based_cleanup_mode_desc
			FROM sys.database_query_store_options'

			SET @i += 1
		end 

		EXEC (@stmt)
		
		SELECT * FROM #tb_qs_db_config_state

		DROP TABLE #tmp
		DROP TABLE #tb_qs_db_config_state
	END TRY
	BEGIN CATCH
		SELECT ERROR_MESSAGE()
	END CATCH
GO
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--Proc Name: sp_qs_state_alert
--Author: Etienne Lopes
--Description: picks up every database where the desired_state_desc is different from the actual_state_desc.
--		Notes: 
--			1 - This stored procedure must be created on master database;

DROP PROCEDURE IF EXISTS sp_qs_state_alert
GO
CREATE PROCEDURE sp_qs_state_alert
AS
	BEGIN TRY
		DECLARE @i int = 1, @MaxID int, @stmt nvarchar(max)
		DECLARE @database_id int, @database_name sysname

		SELECT IDENTITY(int,1,1) AS ID, database_id, name
		INTO #tmp
		FROM sys.databases
		WHERE is_query_store_on = 1

		CREATE TABLE #tb_qs_state_alert 
		(
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

		SELECT @stmt = ''
		SELECT @MaxID = MAX(ID) FROM #tmp
		WHILE @i <= @MaxID
		BEGIN
			SELECT @database_id = database_id, @database_name = name 
			FROM #tmp WHERE ID = @i
	
			SELECT @stmt += '
			USE ' + @database_name + '
			INSERT INTO #tb_qs_state_alert
			(
				database_id, database_name,
				desired_state_desc, actual_state_desc, readonly_reason, current_storage_size_mb,
				max_storage_size_mb, flush_interval_seconds, interval_length_minutes,
				stale_query_threshold_days, max_plans_per_query, query_capture_mode_desc,
				size_based_cleanup_mode_desc
			)
			SELECT ' + CAST(@database_id AS nvarchar) + ', ''' + @database_name + ''',' + '
				desired_state_desc, actual_state_desc, readonly_reason, current_storage_size_mb,
				max_storage_size_mb, flush_interval_seconds, interval_length_minutes,
				stale_query_threshold_days, max_plans_per_query, query_capture_mode_desc,
				size_based_cleanup_mode_desc
			FROM sys.database_query_store_options
			WHERE ISNULL(desired_state_desc, 0) <> ISNULL(actual_state_desc, 0)'

			SET @i += 1
		end 

		EXEC (@stmt)
		
		SELECT * FROM #tb_qs_state_alert

		DROP TABLE #tmp
		DROP TABLE #tb_qs_state_alert

	END TRY
	BEGIN CATCH
		SELECT ERROR_MESSAGE()
	END CATCH
GO


-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--Proc Name: sp_qs_size_alert
--Author: Etienne Lopes
--Description: picks up every database where the current_storage_size_mb is a specified percentage (@percent_full) of max_storage_size_mb 
--		Notes: 
--			1 - This stored procedure must be created on master database;
DROP PROCEDURE IF EXISTS sp_qs_size_alert
GO
CREATE PROCEDURE sp_qs_size_alert @percent_full numeric(3,2) = 0.8
AS
	BEGIN TRY
		DECLARE @i int = 1, @MaxID int, @stmt nvarchar(max)
		DECLARE @database_id int, @database_name sysname

		SELECT IDENTITY(int,1,1) AS ID, database_id, name
		INTO #tmp
		FROM sys.databases
		WHERE is_query_store_on = 1

		CREATE TABLE #tb_qs_state_alert 
		(
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

		SELECT @stmt = ''
		SELECT @MaxID = MAX(ID) FROM #tmp
		WHILE @i <= @MaxID
		BEGIN
			SELECT @database_id = database_id, @database_name = name 
			FROM #tmp WHERE ID = @i
	
			SELECT @stmt += '
			USE ' + @database_name + '
			INSERT INTO #tb_qs_state_alert
			(
				database_id, database_name,
				desired_state_desc, actual_state_desc, readonly_reason, current_storage_size_mb,
				max_storage_size_mb, flush_interval_seconds, interval_length_minutes,
				stale_query_threshold_days, max_plans_per_query, query_capture_mode_desc,
				size_based_cleanup_mode_desc
			)
			SELECT ' + CAST(@database_id AS nvarchar) + ', ''' + @database_name + ''',' + '
				desired_state_desc, actual_state_desc, readonly_reason, current_storage_size_mb,
				max_storage_size_mb, flush_interval_seconds, interval_length_minutes,
				stale_query_threshold_days, max_plans_per_query, query_capture_mode_desc,
				size_based_cleanup_mode_desc
			FROM sys.database_query_store_options
			WHERE ISNULL(current_storage_size_mb, 0) * 1.0 / NULLIF(max_storage_size_mb, 0) >= ' + CAST(@percent_full as nvarchar)

			SET @i += 1
		end 

		EXEC (@stmt)
		
		SELECT * FROM #tb_qs_state_alert

		DROP TABLE #tmp
		DROP TABLE #tb_qs_state_alert

	END TRY
	BEGIN CATCH
		SELECT ERROR_MESSAGE()
	END CATCH
GO

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--Proc Name: sp_qs_lost_object_alert
--Author: Etienne Lopes
--Description: picks up every dropped (hence lost) object in every database that is still referenced by query store.
--		Notes: 
--			- This stored procedure must be created on master database;
--			- Also shows object text to help relating with new release if it's the case.

DROP PROCEDURE IF EXISTS sp_qs_lost_object_alert
GO
CREATE PROCEDURE sp_qs_lost_object_alert
AS
	BEGIN TRY
		DECLARE @i int = 1, @MaxID int, @stmt nvarchar(max)
		DECLARE @database_id int, @database_name sysname, @DBA_database_name sysname

		SELECT IDENTITY(int,1,1) AS ID, database_id, name
		INTO #tmp
		FROM sys.databases
		WHERE is_query_store_on = 1

		CREATE TABLE #tb_qs_db_lost_objects 
		(
			database_id int NOT NULL,
			database_name sysname NOT NULL,
			query_id bigint NULL, 
			lost_object_id bigint NULL, 
			lost_object_sql_text nvarchar(max) NULL, 
			collected_config_date datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET())
		)

		SELECT @stmt = '', @DBA_database_name = DB_NAME()
		SELECT @MaxID = MAX(ID) FROM #tmp
		WHILE @i <= @MaxID
		BEGIN
			SELECT @database_id = database_id, @database_name = name 
			FROM #tmp WHERE ID = @i
	
			SELECT @stmt += '
			USE ' + @database_name + '
			INSERT INTO #tb_qs_db_lost_objects
			(
				database_id, database_name,
				query_id, lost_object_id, lost_object_sql_text
			)
			SELECT ' + CAST(@database_id AS nvarchar) + ', ''' + @database_name + ''',' + '
			qsq.query_id, qsq.object_id as lost_object_id, qsqt.query_sql_text as lost_object_sql_text
			FROM (sys.query_store_query qsq INNER JOIN sys.query_store_query_text qsqt
			ON qsq.query_text_id = qsqt.query_text_id) LEFT JOIN sys.objects o
			ON qsq.object_id = o.object_id
			WHERE (o.object_id IS NULL) AND (qsq.object_id <> 0)'

			SET @i += 1
		end 

		EXEC (@stmt)

		SELECT * FROM #tb_qs_db_lost_objects

		DROP TABLE #tmp
		DROP TABLE #tb_qs_db_lost_objects

	END TRY
	BEGIN CATCH
		SELECT ERROR_MESSAGE()
	END CATCH
GO




