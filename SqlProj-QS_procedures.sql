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

		DROP TABLE #tmp

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
		SELECT 'Table [dbo].[tb_qs_db_config_state] was last uptdated on: ' +  ISNULL(CONVERT(varchar(40), MAX(collected_config_date), 121), 'NEVER!') as Information FROM dbo.tb_qs_db_config_state			
		UNION ALL
		SELECT 'Remember to run stored procedure: [dbo].[usp_get_qs_db_config_state] when you need to refresh data in [dbo].[tb_qs_db_config_state].'

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
		EXEC usp_qs_error_handler 'usp_qs_state_alert'
	END CATCH
GO


-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--Proc Name: usp_qs_size_alert
--Author: Etienne Lopes
--Description: picks up every database where the last current_storage_size_mb is a specified percentage (@percent_full) of max_storage_size_mb 
DROP PROCEDURE IF EXISTS usp_qs_size_alert
GO
CREATE PROCEDURE usp_qs_size_alert @percent_full numeric(3,2) = 0.8
AS
	BEGIN TRY
		SELECT 'Table [dbo].[tb_qs_db_config_state] was last uptdated on: ' +  ISNULL(CONVERT(varchar(40), MAX(collected_config_date), 121), 'NEVER!') as Information FROM dbo.tb_qs_db_config_state			
		UNION ALL
		SELECT 'Remember to run stored procedure: [dbo].[usp_get_qs_db_config_state] when you need to refresh data in [dbo].[tb_qs_db_config_state].'

		;WITH get_last_qs_size
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
		FROM get_last_qs_size
		WHERE ROW_ID = 1
		AND ISNULL(current_storage_size_mb, 0) * 1.0 / NULLIF(max_storage_size_mb, 0) >= @percent_full
	END TRY
	BEGIN CATCH
		EXEC usp_qs_error_handler 'usp_qs_size_alert'
	END CATCH
GO


-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--Proc Name: usp_get_qs_lost_objects
--Author: Etienne Lopes
--Description: Gets objects (for example SPs) that were dropped and are still referenced by query store for every database where is_query_store_on = 1 in the instance.
--			   usage example: 	
--			   Imagine applicational releases are being made using DROP IF EXISTS/CREATE instead of ALTER. A new object with a new object_id will be created with no relation with the previous release of the object to QS eyes.
--			   This SP helps to track these occurences allowing to act accordingly.

--	Notes:
--			- If there are no dropped objects referenced in QS then a new row will be added to table: tb_qs_db_lost_objects with NULL for the columns:  query_id, lost_object_id, lost_object_sql_text.
--			  This will permit to understand that there are no issues at this time. 
--			  Example: 
--				1. There was an old deprecated SP. 
--				2. The SP is dropped. 
--				3. By running usp_get_qs_lost_objects the object_id and its text is written into tb_qs_db_lost_objects.
--				4. Since the SP no longer exists nor has it been replaced by a new one, the DBA decides to run sp_query_store_remove_query to clean Query Store.
--				5. By running usp_get_qs_lost_objects there are now no lost objects in QS, so a new row is added to tb_qs_db_lost_objects allowing the DBA to understand that the cleanup operation was successfull. 
DROP PROCEDURE IF EXISTS usp_get_qs_lost_objects
GO
CREATE PROC usp_get_qs_lost_objects
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
			INSERT INTO ' + @DBA_database_name + '.dbo.tb_qs_db_lost_objects
			(
				database_id, database_name,
				query_id, lost_object_id, lost_object_sql_text
			)
			SELECT ' + CAST(@database_id AS nvarchar) + ', ''' + @database_name + ''',' + '
			qsq.query_id, qsq.object_id as lost_object_id, qsqt.query_sql_text as lost_object_sql_text
			FROM (sys.query_store_query qsq INNER JOIN sys.query_store_query_text qsqt
			ON qsq.query_text_id = qsqt.query_text_id) LEFT JOIN sys.objects o
			ON qsq.object_id = o.object_id
			WHERE (o.object_id IS NULL) AND (qsq.object_id <> 0)
			
			IF NOT EXISTS 
			(
				SELECT 1 FROM (sys.query_store_query qsq INNER JOIN sys.query_store_query_text qsqt
				ON qsq.query_text_id = qsqt.query_text_id) LEFT JOIN sys.objects o
				ON qsq.object_id = o.object_id
				WHERE (o.object_id IS NULL) AND (qsq.object_id <> 0)
			)
			BEGIN
			INSERT INTO ' + @DBA_database_name + '.dbo.tb_qs_db_lost_objects
			(
				database_id, database_name,
				query_id, lost_object_id, lost_object_sql_text
			)
			SELECT ' + CAST(@database_id AS nvarchar) + ', ''' + @database_name + ''',' + '
			NULL, NULL, NULL
			END
			'

			SET @i += 1
		end 

		EXEC (@stmt)

		DROP TABLE #tmp

	END TRY
	BEGIN CATCH
		EXEC usp_qs_error_handler 'usp_get_qs_lost_objects'
	END CATCH
GO

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--Proc Name: usp_qs_lost_object_alert
--Author: Etienne Lopes
--Description: picks up every dropped (hence lost) object in every database that is still referenced by query store.
--		Notes: 
--			- Also shows object text to help relating with new release if it's the case.
--			- This SP reads from table tb_qs_db_lost_objects which in turn is refreshed via SP: usp_get_qs_lost_objects.

DROP PROCEDURE IF EXISTS usp_qs_lost_object_alert
GO
CREATE PROCEDURE usp_qs_lost_object_alert
AS
	BEGIN TRY
		SELECT 'Table [dbo].[tb_qs_db_lost_objects] was last uptdated on: ' +  ISNULL(CONVERT(varchar(40), MAX(collected_config_date), 121), 'NEVER!') as Information FROM dbo.tb_qs_db_lost_objects			
		UNION ALL
		SELECT 'Remember to run stored procedure: [dbo].[usp_get_qs_lost_objects] when you need to refresh data in [dbo].[tb_qs_db_lost_objects].'

		;WITH get_last_qs_lost_objects
		AS
		(
			SELECT	ROW_NUMBER() OVER (PARTITION BY (database_id) ORDER BY collected_config_date DESC) as ROW_ID,
					lost_objects_ID, database_id, database_name, query_id, lost_object_id, 
					lost_object_sql_text, collected_config_date
			FROM dbo.tb_qs_db_lost_objects			
		)
		SELECT 		lost_objects_ID, database_id, database_name, query_id, lost_object_id, 
					lost_object_sql_text, collected_config_date
		FROM get_last_qs_lost_objects
		WHERE ROW_ID = 1
		AND query_id IS NOT NULL
	END TRY
	BEGIN CATCH
		EXEC usp_qs_error_handler 'usp_qs_lost_object_alert'
	END CATCH
GO


