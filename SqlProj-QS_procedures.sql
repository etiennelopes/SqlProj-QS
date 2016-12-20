USE DBADATABASE
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--Proc Name: usp_qs_error_handler
--Author: Etienne Lopes
--Description: Created for error handling inside stored procedures
DROP PROCEDURE IF EXISTS usp_qs_error_handler 
GO
CREATE PROCEDURE usp_qs_error_handler @p_proc_name sysname = NULL
AS
	INSERT INTO dbo.tb_qs_errors (error_num, error_msg, error_proc)
	SELECT ERROR_NUMBER(), ERROR_MESSAGE(), @p_proc_name
GO
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

--Proc Name: usp_get_qs_db_config_state
--Author: Etienne Lopes
--Description: collects configuration data from every database where is_query_store_on = 1 in the instance into a table called: tb_qs_db_config_state 
DROP PROCEDURE IF EXISTS usp_get_qs_db_config_state
GO
CREATE PROC usp_get_qs_db_config_state
AS
	BEGIN TRY
		DECLARE @i int = 1, @MaxID int, @stmt nvarchar(max)
		DECLARE @database_id int, @database_name sysname, @DBA_database_name sysname

		SELECT IDENTITY(int,1,1) AS ID, database_id, name
		INTO #tmp
		FROM sys.databases
		WHERE is_query_store_on = 1

		SELECT @stmt = '', @DBA_database_name = DB_NAME()
		SELECT @MaxID = MAX(ID) FROM #tmp
		WHILE @i <= @MaxID
		BEGIN
			SELECT @database_id = database_id, @database_name = name 
			FROM #tmp WHERE ID = @i
	
			SELECT @stmt += '
			USE ' + @database_name + '
			INSERT INTO ' + @DBA_database_name + '.dbo.tb_qs_db_config_state
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
	END TRY
	BEGIN CATCH
		EXEC usp_qs_error_handler 'usp_get_qs_db_config_state'
	END CATCH
GO
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--Proc Name: usp_qs_state_alert
--Author: Etienne Lopes
--Description: picks up every database where the last desired_state_desc is different from the actual_state_desc
DROP PROCEDURE IF EXISTS usp_qs_state_alert
GO
CREATE PROCEDURE usp_qs_state_alert
AS
	BEGIN TRY
		;WITH get_last_qs_state
		AS
		(
			SELECT	ROW_NUMBER() OVER (PARTITION BY (database_id) ORDER BY collected_config_date DESC) as ROW_ID,
					Config_ID, database_id, database_name, desired_state_desc, actual_state_desc, readonly_reason, 
					current_storage_size_mb, max_storage_size_mb, flush_interval_seconds, interval_length_minutes, 
					stale_query_threshold_days, max_plans_per_query, query_capture_mode_desc, 
					size_based_cleanup_mode_desc, collected_config_date
			FROM dbo.tb_qs_db_config_state			
		)
		SELECT 		Config_ID, database_id, database_name, desired_state_desc, actual_state_desc, readonly_reason, 
					current_storage_size_mb, max_storage_size_mb, flush_interval_seconds, interval_length_minutes, 
					stale_query_threshold_days, max_plans_per_query, query_capture_mode_desc, 
					size_based_cleanup_mode_desc, collected_config_date
		FROM get_last_qs_state
		WHERE ROW_ID = 1
		AND ISNULL(desired_state_desc, 0) <> ISNULL(actual_state_desc, 0)
	END TRY
	BEGIN CATCH
		EXEC usp_qs_error_handler 'usp_get_qs_db_config_state'
	END CATCH
GO


