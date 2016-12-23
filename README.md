# SqlProj-QS


Hi,

Query Store is a great new feature that comes with SQL Server 2016 and I suspect will have a large acceptance among the DBAs.

As DBAs we need to manage not just one but many/all databases in one (or many) instance(s). 

Query Store has a number of configuration options that are very important to manage and monitor in order to ensure it's working properly. 

Let me give you just an example, query store may be configured for **READ_WRITE** but if the maximum storage size is reached then it will automatically change to **READ_ONLY**. If you're not aware of this change you may have a bad surprise in the future when you're troubleshooting some query behavior in the database. And yes, the scope of Query Store is the database, not the instance.

If there are many databases in each instance, monitoring all these settings properly and regularly can become a hard task so, long story short, I've decided to implement a kind of a (T-SQL) tool that would simplify monitoring Query Store at the instance level, for all its databases at once :-)

Starting with a stored procedure that collects and presents relevant configuration data from every database where is_query_store_on = 1 in the instance :-)


This will come in two flavors:

1. Simply creating the stored procedures on master database, offering the possibility to obtain snapshots of the current settings for all databases in the instance at once. Code available in:

   - **SqlProj-QS_system_procedures.sql**  
     
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; **Proc Name**: sp_get_qs_db_config_state  
    

   
2. Creating a DBADATABASE in the instance, allowing to keep the history of what has happened along the way for each database. Code available in:
   - SqlProj-QS_tables.sql;
   - SqlProj-QS_procedures.sql



This is the beginning of the project and there will be some updates until the end of this year 😊


