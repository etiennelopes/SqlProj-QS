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
	END TRY
	BEGIN CATCH
		SELECT ERROR_MESSAGE()
	END CATCH
GO



