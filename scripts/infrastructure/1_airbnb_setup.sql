-- =============================================================================
-- FULL ENVIRONMENT SETUP (Snowflake Scripting - Single Block)
-- Purpose: Create all infrastructure using loops over databases, schemas, roles
-- Run as: ACCOUNTADMIN
-- Global Variables: databases, schemas, roles (declared once, used throughout)
-- Idempotent: Uses IF NOT EXISTS throughout — safe to re-run without data loss
-- =============================================================================

USE ROLE ACCOUNTADMIN;

BEGIN
    -- =========================================================================
    -- GLOBAL VARIABLES (defined once, reused in all sections)
    -- =========================================================================
    LET databases ARRAY := ARRAY_CONSTRUCT('DB_AIRBNB_DEV', 'DB_AIRBNB_TEST', 'DB_AIRBNB');
    LET schemas ARRAY := ARRAY_CONSTRUCT('STAGING', 'BRONZE', 'SILVER', 'GOLD');
    LET roles ARRAY := ARRAY_CONSTRUCT('dbt_dev_role', 'dbt_test_role', 'dbt_prod_role');

    -- =========================================================================
    -- SECTION 1: CREATE DATABASES
    -- =========================================================================
    FOR i IN 0 TO ARRAY_SIZE(:databases) - 1 DO
        EXECUTE IMMEDIATE 'CREATE DATABASE IF NOT EXISTS ' || :databases[:i];
    END FOR;

    -- =========================================================================
    -- SECTION 2: CREATE ROLES, ASSIGN TO USER, AND ESTABLISH ROLE HIERARCHY
    -- =========================================================================
    FOR i IN 0 TO ARRAY_SIZE(:roles) - 1 DO
        EXECUTE IMMEDIATE 'CREATE ROLE IF NOT EXISTS ' || :roles[:i];
        EXECUTE IMMEDIATE 'GRANT ROLE ' || :roles[:i] || ' TO USER SHREE';
        -- Role hierarchy: custom roles roll up to SYSADMIN per Snowflake best practice
        EXECUTE IMMEDIATE 'GRANT ROLE ' || :roles[:i] || ' TO ROLE SYSADMIN';
    END FOR;

    -- =========================================================================
    -- SECTION 3: CREATE SCHEMAS IN ALL DATABASES
    -- =========================================================================
    FOR i IN 0 TO ARRAY_SIZE(:databases) - 1 DO
        FOR j IN 0 TO ARRAY_SIZE(:schemas) - 1 DO
            EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS ' || :databases[:i] || '.' || :schemas[:j];
        END FOR;
    END FOR;

    -- =========================================================================
    -- SECTION 4: CREATE TABLES IN STAGING SCHEMA (all databases)
    -- =========================================================================
    FOR i IN 0 TO ARRAY_SIZE(:databases) - 1 DO
        LET db VARCHAR := :databases[:i];

        EXECUTE IMMEDIATE '
            CREATE TABLE IF NOT EXISTS ' || :db || '.STAGING.HOSTS (
                host_id NUMBER,
                host_name STRING,
                host_since DATE,
                is_superhost BOOLEAN,
                response_rate NUMBER,
                created_at TIMESTAMP,
                FILENAME STRING,
                FILE_ROW_NUMBER INT,
                FILE_CONTENT_KEY STRING,
                FILE_LAST_MODIFIED TIMESTAMP_NTZ(9),
                START_SCAN_TIME TIMESTAMP_NTZ(9),
                PRIMARY KEY (host_id)
            )';

        EXECUTE IMMEDIATE '
            CREATE TABLE IF NOT EXISTS ' || :db || '.STAGING.LISTINGS (
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
                FILE_LAST_MODIFIED TIMESTAMP_NTZ(9),
                START_SCAN_TIME TIMESTAMP_NTZ(9),
                PRIMARY KEY (listing_id)
            )';

        EXECUTE IMMEDIATE '
            CREATE TABLE IF NOT EXISTS ' || :db || '.STAGING.BOOKINGS (
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
                FILE_LAST_MODIFIED TIMESTAMP_NTZ(9),
                START_SCAN_TIME TIMESTAMP_NTZ(9),
                PRIMARY KEY (booking_id)
            )';
    END FOR;

    -- =========================================================================
    -- SECTION 5: FILE FORMATS IN STAGING SCHEMA (all databases)
    -- =========================================================================
    FOR i IN 0 TO ARRAY_SIZE(:databases) - 1 DO
        LET db VARCHAR := :databases[:i];

        EXECUTE IMMEDIATE '
            CREATE FILE FORMAT IF NOT EXISTS ' || :db || '.STAGING.CSV_FORMAT
                TYPE = CSV
                FIELD_DELIMITER = '',''
                FIELD_OPTIONALLY_ENCLOSED_BY = ''"''
                SKIP_HEADER = 1
                EMPTY_FIELD_AS_NULL = FALSE
                NULL_IF = (''NULL'')';

        EXECUTE IMMEDIATE '
            CREATE FILE FORMAT IF NOT EXISTS ' || :db || '.STAGING.CSV_FORMAT_HEADER_METADATA
                TYPE = CSV
                FIELD_DELIMITER = '',''
                FIELD_OPTIONALLY_ENCLOSED_BY = ''"''
                ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
                PARSE_HEADER = TRUE
                EMPTY_FIELD_AS_NULL = FALSE
                NULL_IF = (''NULL'')';
    END FOR;

    -- =========================================================================
    -- SECTION 6: STORAGE INTEGRATION (single shared resource)
    -- NOTE: STORAGE_AWS_ROLE_ARN must be updated per AWS account.
    --       After creation, run DESCRIBE INTEGRATION IO_AIRBNB to get the
    --       STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID values
    --       needed to configure the IAM trust policy in AWS.
    --       Using IF NOT EXISTS to preserve the external ID on re-runs.
    -- =========================================================================
    EXECUTE IMMEDIATE '
        CREATE STORAGE INTEGRATION IF NOT EXISTS IO_AIRBNB
            TYPE = EXTERNAL_STAGE
            STORAGE_PROVIDER = ''S3''
            ENABLED = TRUE
            STORAGE_AWS_ROLE_ARN = ''arn:aws:iam::125206151949:role/SnowflakePipeline''
            STORAGE_ALLOWED_LOCATIONS = (''s3://ppairbnb1/source/'')
            COMMENT = ''Integration to access ppairbnb1 S3 bucket for Airbnb data''';

    -- =========================================================================
    -- SECTION 7: EXTERNAL STAGES IN STAGING SCHEMA (all databases)
    -- =========================================================================
    FOR i IN 0 TO ARRAY_SIZE(:databases) - 1 DO
        LET db VARCHAR := :databases[:i];

        EXECUTE IMMEDIATE '
            CREATE STAGE IF NOT EXISTS ' || :db || '.STAGING.STG_AIRBNB_S3
                STORAGE_INTEGRATION = IO_AIRBNB
                URL = ''s3://ppairbnb1/source/''
                FILE_FORMAT = ' || :db || '.STAGING.CSV_FORMAT';

        EXECUTE IMMEDIATE '
            ALTER STAGE ' || :db || '.STAGING.STG_AIRBNB_S3 SET DIRECTORY = (ENABLE = TRUE)';
    END FOR;

    -- =========================================================================
    -- SECTION 8: ALL GRANTS (looped over database-role pairs)
    -- =========================================================================

    -- Grants per role mapped to its database (dev→dev, test→test, prod→prod)
    FOR i IN 0 TO ARRAY_SIZE(:databases) - 1 DO
        LET db VARCHAR := :databases[:i];
        LET role_name VARCHAR := :roles[:i];

        EXECUTE IMMEDIATE 'GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ' || :role_name;
        EXECUTE IMMEDIATE 'GRANT USAGE ON DATABASE ' || :db || ' TO ROLE ' || :role_name;
        EXECUTE IMMEDIATE 'GRANT CREATE SCHEMA ON DATABASE ' || :db || ' TO ROLE ' || :role_name;
        EXECUTE IMMEDIATE 'GRANT USAGE ON ALL SCHEMAS IN DATABASE ' || :db || ' TO ROLE ' || :role_name;
        EXECUTE IMMEDIATE 'GRANT USAGE ON INTEGRATION IO_AIRBNB TO ROLE ' || :role_name;

        -- Schema-level grants for each schema
        FOR j IN 0 TO ARRAY_SIZE(:schemas) - 1 DO
            LET sch VARCHAR := :schemas[:j];
            EXECUTE IMMEDIATE 'GRANT CREATE TABLE ON SCHEMA ' || :db || '.' || :sch || ' TO ROLE ' || :role_name;
            EXECUTE IMMEDIATE 'GRANT CREATE VIEW ON SCHEMA ' || :db || '.' || :sch || ' TO ROLE ' || :role_name;
            EXECUTE IMMEDIATE 'GRANT CREATE STAGE ON SCHEMA ' || :db || '.' || :sch || ' TO ROLE ' || :role_name;
            EXECUTE IMMEDIATE 'GRANT USAGE ON SCHEMA ' || :db || '.' || :sch || ' TO ROLE ' || :role_name;
            EXECUTE IMMEDIATE 'GRANT SELECT ON ALL TABLES IN SCHEMA ' || :db || '.' || :sch || ' TO ROLE ' || :role_name;
            EXECUTE IMMEDIATE 'GRANT SELECT ON FUTURE TABLES IN SCHEMA ' || :db || '.' || :sch || ' TO ROLE ' || :role_name;
        END FOR;

        -- Stage and file format grants (staging schema)
        EXECUTE IMMEDIATE 'GRANT USAGE ON STAGE ' || :db || '.STAGING.STG_AIRBNB_S3 TO ROLE ' || :role_name;
        EXECUTE IMMEDIATE 'GRANT USAGE ON FILE FORMAT ' || :db || '.STAGING.CSV_FORMAT TO ROLE ' || :role_name;
        EXECUTE IMMEDIATE 'GRANT USAGE ON FILE FORMAT ' || :db || '.STAGING.CSV_FORMAT_HEADER_METADATA TO ROLE ' || :role_name;

        -- Future grants at database level
        EXECUTE IMMEDIATE 'GRANT USAGE ON FUTURE SCHEMAS IN DATABASE ' || :db || ' TO ROLE ' || :role_name;
        EXECUTE IMMEDIATE 'GRANT CREATE TABLE ON FUTURE SCHEMAS IN DATABASE ' || :db || ' TO ROLE ' || :role_name;
        EXECUTE IMMEDIATE 'GRANT CREATE VIEW ON FUTURE SCHEMAS IN DATABASE ' || :db || ' TO ROLE ' || :role_name;
    END FOR;

    -- SYSADMIN grants across all databases
    FOR i IN 0 TO ARRAY_SIZE(:databases) - 1 DO
        LET db VARCHAR := :databases[:i];
        EXECUTE IMMEDIATE 'GRANT USAGE ON DATABASE ' || :db || ' TO ROLE SYSADMIN';
        FOR j IN 0 TO ARRAY_SIZE(:schemas) - 1 DO
            LET sch VARCHAR := :schemas[:j];
            EXECUTE IMMEDIATE 'GRANT USAGE ON SCHEMA ' || :db || '.' || :sch || ' TO ROLE SYSADMIN';
            EXECUTE IMMEDIATE 'GRANT ALL ON SCHEMA ' || :db || '.' || :sch || ' TO ROLE SYSADMIN';
        END FOR;
    END FOR;
    EXECUTE IMMEDIATE 'GRANT USAGE ON INTEGRATION IO_AIRBNB TO ROLE SYSADMIN';

EXCEPTION
    WHEN OTHER THEN
        LET err_msg VARCHAR := SQLERRM;
        EXECUTE IMMEDIATE 'SELECT ''ERROR: ' || :err_msg || ''' AS error_message';
        RAISE;
END;

-- =============================================================================
-- VERIFICATION (run separately after the block completes)
-- =============================================================================
SHOW GRANTS TO ROLE dbt_dev_role;
SHOW GRANTS TO ROLE dbt_test_role;
SHOW GRANTS TO ROLE dbt_prod_role;
DESCRIBE STORAGE INTEGRATION IO_AIRBNB;
