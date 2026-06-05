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
 
