# SqlProj-QS


Hi,

Query Store is a great new feature that comes with SQL Server 2016 and I suspect will have a large acceptance among the DBAs.

As DBAs we need to manage not just one but many/all databases in one (or many) instance(s). 

Query Store has a number of configuration options that are very important to manage and monitor in order to ensure it's working properly. 

Let me give you just an example, query store may be configured for **READ_WRITE** but if the maximum storage size is reached then it will automatically change to **READ_ONLY**. If you're not aware of this change you may have a bad surprise in the future when you're troubleshooting some query behavior in the database. And yes, the scope of Query Store is the database, not the instance.

If there are many databases in each instance, monitoring all these settings properly and regularly can become a hard task so, long story short, I've decided to implement a kind of a (T-SQL) tool that would simplify monitoring Query Store at the instance level, for all its databases at once :-)

This will come in two flavors:

1. Simply creating the stored procedures on master database, offering the possibility to obtain snapshots of the current settings for all databases in the instance at once. Code and comments available in:

   - **SqlProj-QS_system_procedures.sql - See uploaded file**  
     
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Proc Name**: sp_get_qs_db_config_state  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Description: Shows current configuration data from every database where is_query_store_on = 1 in the instance.  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Notes:  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;- This stored procedure must be created on master database;  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;- The results are sent to the std output and (unlike the other version) they're not persisted.  
     
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Proc Name**: sp_qs_state_alert  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Description: picks up every database where the desired_state_desc is different from the actual_state_desc.  
   
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Proc Name**: sp_qs_size_alert  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Description: picks up every database where the current_storage_size_mb is a specified percentage (@percent_full) of max_storage_size_mb  
   
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Proc Name**: sp_qs_lost_object_alert  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Description: picks up every dropped (hence lost) object in every database that is still referenced by query store.  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Notes:  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Also shows object text to help relating with new release if it's the case.  
   
   
   
2. Creating a DBADATABASE in the instance, allowing to keep the history of what has happened along the way for each database. Code and comments available in:
   - **SqlProj-QS_tables.sql - See uploaded file**  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Table Name**: tb_qs_db_config_state  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Description: holds configuration data from every database where is_query_store_on = 1 in the instance.  
   
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Table Name**: tb_qs_db_lost_objects  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Description: holds information about objects (for example SPs) that were dropped and are still referenced by query store, for every database where is_query_store_on = 1 in the instance.  
   
   - **SqlProj-QS_procedures.sql - See uploaded file**    
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Proc Name**: usp_get_qs_db_config_state  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Description: collects configuration data from every database where is_query_store_on = 1 in the instance into a table called: tb_qs_db_config_state  
   
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Proc Name**: usp_qs_state_alert  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Description: picks up every database where the last desired_state_desc is different from the actual_state_desc  
   
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Proc Name**: usp_qs_size_alert  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Description: picks up every database where the last current_storage_size_mb is a specified percentage (@percent_full) of max_storage_size_mb  
   
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Proc Name**: usp_get_qs_lost_objects  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Description: Gets objects (for example SPs) that were dropped and are still referenced by query store for every database where is_query_store_on = 1 in the instance.  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;usage example:  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Imagine applicational releases are being made using DROP IF EXISTS/CREATE instead of ALTER. A new object with a new object_id will be created with no relation with the previous release of the object to QS eyes.  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;This SP helps to track these occurences allowing to act accordingly.  
   
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Proc Name**: usp_qs_lost_object_alert  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Description: picks up every dropped (hence lost) object in every database that is still referenced by query store.  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Notes:  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;- Also shows object text to help relating with new release if it's the case.  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;- This SP reads from table tb_qs_db_lost_objects which in turn is refreshed via SP: usp_get_qs_lost_objects.  
     
       
         
And there is more to come as soon as I can find the time :-)
   
   

