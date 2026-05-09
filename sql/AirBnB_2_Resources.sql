USE DB_AIRBNB.SCH_AIRBNB;
USE ROLE ACCOUNTADMIN;
USE DB_AIRBNB.SCH_AIRBNB;

USE ROLE ACCOUNTADMIN;
GRANT USAGE ON DATABASE DB_AIRBNB TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA SCH_AIRBNB TO ROLE SYSADMIN;
--SHOW GRANTS;

GRANT OWNERSHIP ON SCHEMA SCH_AIRBNB TO ROLE SYSADMIN REVOKE CURRENT GRANTS;

/* 
    We create two file format objects:
    - one for regular data loading (CSV_FORMAT) 
    - another that captures metadata (CSV_FORMAT_HEADER_METADATA) which is useful for debugging and lineage.
*/
USE ROLE SYSADMIN;
CREATE FILE FORMAT IF NOT EXISTS CSV_FORMAT
    TYPE = CSV
    FIELD_DELIMITER = ','   
    FIELD_OPTIONALLY_ENCLOSED_BY = '"' 
    SKIP_HEADER = 1
    EMPTY_FIELD_AS_NULL = FALSE
    NULL_IF = ('NULL');


CREATE FILE FORMAT IF NOT EXISTS CSV_FORMAT_HEADER_METADATA  -- Use only when capturing metadata 
    TYPE = CSV
    FIELD_DELIMITER = ','
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE  -- avoids the column count mismatch due to metadata info
    PARSE_HEADER = TRUE
    EMPTY_FIELD_AS_NULL = FALSE
    NULL_IF = ('NULL');

SHOW FILE FORMATS;
DESCRIBE FILE FORMAT CSV_FORMAT;


/* 
    Storage integration  -  Integration object can be created by accountadmin role only. 
    It abstracts away the credentials and provides a secure way to access external storage.
    This object defines the permissions and access controls for Snowflake to interact with the S3 bucket.
    We will use this integration in our stage definition to load data from S3 into Snowflake.
    
*/
USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE STORAGE INTEGRATION IO_AIRBNB
	     TYPE = EXTERNAL_STAGE
	     STORAGE_PROVIDER = 'S3'
	     ENABLED = TRUE
	     STORAGE_AWS_ROLE_ARN='arn:aws:iam::125206151949:role/SnowflakePipeline'             
       STORAGE_ALLOWED_LOCATIONS =('s3://ppairbnb1/source/')
       COMMENT = 'Integration to access ppairbnb1 bucket'
	    ;
	    

GRANT USAGE ON INTEGRATION IO_AIRBNB TO ROLE SYSADMIN;

SHOW INTEGRATIONS;

DESCRIBE STORAGE INTEGRATION IO_AIRBNB;

-- Privileges granted ON a specific object
SHOW GRANTS ON DATABASE DB_AIRBNB;
SHOW GRANTS ON SCHEMA DB_AIRBNB.STAGING;

-- grant all previleges to sysadmin on db_airbnb.staging
GRANT ALL ON SCHEMA DB_AIRBNB.STAGING TO ROLE SYSADMIN;


/* 
  Create stage object to bring raw data from S3 bucket. 
  The stage is linked to the storage integration which handles the authentication and access to the S3 bucket. 
  We specify the file format to use when loading data from this stage. 
  We will use these stage objects in copy command to load data into staging tables.
*/
CREATE STAGE STG_AIRBNB_S3
STORAGE_INTEGRATION = IO_AIRBNB  
URL = 's3://ppairbnb1/source/'
FILE_FORMAT = CSV_FORMAT;


-- Test stage access: list files in S3 via the stage
LIST @STG_AIRBNB_S3;


-- -- enable a directory on existing stage
-- ALTER STAGE STG_AIRBNB_S3 SET DIRECTORY = (ENABLE = TRUE);

-- --refresh directory metadata table
-- ALTER STAGE STG_AIRBNB_S3 REFRESH;

SHOW STAGES;

-- querying staged files
SELECT * FROM DIRECTORY(@STG_AIRBNB_S3);

LIST @STG_AIRBNB;


-- Example with filters:
SELECT relative_path, size, last_modified FROM DIRECTORY(@STG_AIRBNB_S3);

