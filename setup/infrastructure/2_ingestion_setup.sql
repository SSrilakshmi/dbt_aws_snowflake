/*
========================================================================
Purpose:    Creates tables and pipes in _Raw.Staging schema for data landing
Dependency: Requires 01_environment_setup.sql to be run
Author:     Shree
========================================================================            
*/

USE DB_AIRBNB_RAW.STAGING;

-- Create raw tables
-- ============================================================
-- HOSTS TABLE
-- ============================================================

EXECUTE IMMEDIATE '
CREATE TABLE IF NOT EXISTS DB_AIRBNB_RAW.STAGING.HOSTS (
    host_id NUMBER,
    host_name STRING,
    host_since DATE,
    is_superhost BOOLEAN,
    response_rate NUMBER,
    created_at TIMESTAMP,
    FILENAME STRING,
    FILE_ROW_NUMBER INT,
    FILE_CONTENT_KEY STRING,
    FILE_LAST_MODIFIED TIMESTAMP_NTZ,
    START_SCAN_TIME TIMESTAMP_NTZ,
    PRIMARY KEY (host_id)
)';

-- ============================================================
-- LISTINGS TABLE
-- ============================================================
EXECUTE IMMEDIATE '
CREATE TABLE IF NOT EXISTS DB_AIRBNB_RAW.STAGING.LISTINGS (
    listing_id NUMBER,
    host_id NUMBER,
    property_type STRING,
    room_type STRING,
    city STRING,
    country STRING,
    accommodates NUMBER,
    bedrooms NUMBER,
    bathrooms NUMBER,
    price_per_night NUMBER,
    created_at TIMESTAMP,
    FILENAME STRING,
    FILE_ROW_NUMBER INT,
    FILE_CONTENT_KEY STRING,
    FILE_LAST_MODIFIED TIMESTAMP_NTZ,
    START_SCAN_TIME TIMESTAMP_NTZ,
    PRIMARY KEY (listing_id)
)';

-- ============================================================
-- BOOKINGS TABLE
-- ============================================================

EXECUTE IMMEDIATE '
CREATE TABLE IF NOT EXISTS DB_AIRBNB_RAW.STAGING.BOOKINGS (
    booking_id STRING,
    listing_id NUMBER,
    booking_date TIMESTAMP,
    nights_booked NUMBER,
    booking_amount NUMBER,
    cleaning_fee NUMBER,
    service_fee NUMBER,
    booking_status STRING,
    created_at TIMESTAMP,
    FILENAME STRING,
    FILE_ROW_NUMBER INT,
    FILE_CONTENT_KEY STRING,
    FILE_LAST_MODIFIED TIMESTAMP_NTZ,
    START_SCAN_TIME TIMESTAMP_NTZ,
    PRIMARY KEY (booking_id)
)';

-- ============================================================
-- File formats
-- ============================================================
CREATE FILE FORMAT IF NOT EXISTS
DB_AIRBNB_RAW.STAGING.CSV_FORMAT
TYPE = CSV
FIELD_DELIMITER=','
FIELD_OPTIONALLY_ENCLOSED_BY='"'
SKIP_HEADER=1;

CREATE FILE FORMAT IF NOT EXISTS
DB_AIRBNB_RAW.STAGING.CSV_FORMAT_HEADER_METADATA
TYPE = CSV
PARSE_HEADER=TRUE
ERROR_ON_COLUMN_COUNT_MISMATCH=FALSE;

-- ============================================================
-- Storage integraton
-- ============================================================
CREATE STORAGE INTEGRATION IF NOT EXISTS IO_AIRBNB
TYPE=EXTERNAL_STAGE
STORAGE_PROVIDER='S3'
ENABLED=TRUE
STORAGE_AWS_ROLE_ARN=
'arn:aws:iam::125206151949:role/SnowflakePipeline'
STORAGE_ALLOWED_LOCATIONS=
('s3://ppairbnb1/source/');

-- ============================================================
-- Stage
-- ============================================================
CREATE STAGE IF NOT EXISTS
DB_AIRBNB_RAW.STAGING.STG_AIRBNB_S3
STORAGE_INTEGRATION=IO_AIRBNB
URL='s3://ppairbnb1/source/'
FILE_FORMAT=DB_AIRBNB_RAW.STAGING.CSV_FORMAT;

-- ============================================================
-- Pipes
-- ============================================================
DECLARE
    -- Arrays
    arr_tables      ARRAY;
    arr_pipes       ARRAY;
    arr_stages      ARRAY;

    -- Variables
    tbl_name        VARCHAR;
    pipe_name       VARCHAR;
    stg_path        VARCHAR;
    file_pattern    VARCHAR;
    sql_stmt        VARCHAR;

    -- Counters
    i               INTEGER;

BEGIN

    -- Single query to populate all arrays
    SELECT ARRAY_AGG(TABLE_NAME), ARRAY_AGG(PIPE_NAME), ARRAY_AGG(STAGE_PATH)
        INTO :arr_tables, :arr_pipes, :arr_stages
        FROM DB_AIRBNB_ADMIN.CONFIG.CONFIG_TABLES;

    FOR i IN 0 TO ARRAY_SIZE(arr_tables) - 1 DO
        tbl_name     := TRIM(arr_tables[i]::VARCHAR, '"');
        pipe_name    := TRIM(arr_pipes[i]::VARCHAR, '"');
        stg_path     := TRIM(arr_stages[i]::VARCHAR, '"');
        file_pattern := '.*' || LOWER(tbl_name) || '.*[.]csv';
        


    sql_stmt :=
    'CREATE PIPE IF NOT EXISTS DB_AIRBNB_RAW.STAGING.'
    || pipe_name
    || '
    AUTO_INGEST=TRUE
    AS
    COPY INTO DB_AIRBNB_RAW.STAGING.'
    || tbl_name
    || '
    FROM ' || stg_path || '
    PATTERN='''
    || file_pattern
    || '''
    FILE_FORMAT=
      (FORMAT_NAME=
      DB_AIRBNB_RAW.STAGING.CSV_FORMAT_HEADER_METADATA)
    MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE
    ON_ERROR=''CONTINUE''
    INCLUDE_METADATA=
    (
      FILENAME=METADATA$FILENAME,
      FILE_ROW_NUMBER=METADATA$FILE_ROW_NUMBER,
      FILE_CONTENT_KEY=METADATA$FILE_CONTENT_KEY,
      FILE_LAST_MODIFIED=METADATA$FILE_LAST_MODIFIED,
      START_SCAN_TIME=METADATA$START_SCAN_TIME
    )';

    EXECUTE IMMEDIATE sql_stmt;

END FOR;

END;

/*
DESCRIBE STORAGE INTEGRATION IO_AIRBN;
DESCRIBE PIPE DB_AIRBNB_RAW.STAGING.BOOKINGS_PIPE;
DESCRIBE PIPE DB_AIRBNB_RAW.STAGING.LISTINGS_PIPE;
DESCRIBE PIPE DB_AIRBNB_RAW.STAGING.HOSTS_PIPE;
*/