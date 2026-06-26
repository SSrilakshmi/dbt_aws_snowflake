USE DB_AIRBNB_RAW.STAGING;

-- Obtain the value for notificatio_channel to AWS - SQS Queue ARN
DESCRIBE PIPE BOOKINGS_PIPE;


SHOW PIPES IN DB_AIRBNB_RAW.STAGING;


-- ============================
-- Debug pipe
-- ============================
-- check ingestion
USE DB_AIRBNB_RAW;
SELECT *
FROM INFORMATION_SCHEMA.LOAD_HISTORY
ORDER BY LAST_LOAD_TIME DESC;


-- get generated copy statements
SHOW PIPES IN DB_AIRBNB_RAW.STAGING;

-- list all pipes in the staging area  
LIST @DB_AIRBNB_RAW.STAGING.STG_AIRBNB_S3;

-- check pipe status
SELECT SYSTEM$PIPE_STATUS('DB_AIRBNB_RAW.STAGING.BOOKINGS_PIPE'); 
SELECT SYSTEM$PIPE_STATUS('DB_AIRBNB_RAW.STAGING.HOSTS_PIPE'); 
SELECT SYSTEM$PIPE_STATUS('DB_AIRBNB_RAW.STAGING.LISTINGS_PIPE'); 
 

 -- did the snowpipe move data to corresponding tables
select count(*) from db_airbnb_raw.staging.bookings; -- 7416
select count(*) from db_airbnb_raw.staging.listings; -- 1491
select count(*) from db_airbnb_raw.staging.hosts; -- 500


select count(*) from db_airbnb_dev.bronze.bronze_bookings; -- 7416
select count(*) from db_airbnb_dev.bronze.bronze_listings; --1491
select count(*) from db_airbnb_dev.bronze.bronze_hosts; -- 500

-- obtain definition of pipe
DESCRIBE PIPE DB_AIRBNB_RAW.STAGING.HOSTS_PIPE;


-- Pipe usage history provides credits used. Pipe_name is diaplayed only when credits are actually billed
SELECT * FROM TABLE(
    DB_AIRBNB_RAW.INFORMATION_SCHEMA.PIPE_USAGE_HISTORY(
        DATE_RANGE_START => DATEADD('day', -14, CURRENT_DATE())
    )
);

-- pipe usage perload file details in the past seven days
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.COPY_HISTORY
WHERE pipe_catalog_name = 'DB_AIRBNB_RAW'
  AND pipe_schema_name = 'STAGING'
  AND last_load_time >= DATEADD('day', -7, CURRENT_DATE())
ORDER BY last_load_time DESC;