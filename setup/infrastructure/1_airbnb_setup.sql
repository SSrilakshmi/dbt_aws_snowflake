-- =============================================================================
-- FULL ENVIRONMENT SETUP (Snowflake Scripting - Single Block)
-- Purpose: Create all infrastructure using loops over databases, schemas, roles
-- Run as: ACCOUNTADMIN
-- Global Variables: databases, schemas, roles (declared once, used throughout)
-- Idempotent: Uses IF NOT EXISTS throughout — safe to re-run without data loss
-- =============================================================================

USE ROLE ACCOUNTADMIN;

BEGIN
    -- For debugging generated ddl statements
    CREATE DATABASE IF NOT EXISTS DB_AIRBNB_DEBUG;
    CREATE OR REPLACE TABLE DB_AIRBNB_DEBUG.PUBLIC.SECTION_DEBUG (
        section STRING,
        object_name STRING,
        ddl STRING,
        created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
    );
END;

BEGIN
    -- =========================================================================
    -- GLOBAL VARIABLES (defined once, reused in all sections)
    -- =========================================================================
    LET arr_databases ARRAY := ARRAY_CONSTRUCT('DB_AIRBNB_RAW', 'DB_AIRBNB_DEV', 'DB_AIRBNB_TEST', 'DB_AIRBNB');
    LET arr_schemas ARRAY := ARRAY_CONSTRUCT('STAGING', 'BRONZE', 'SILVER', 'GOLD');
    LET arr_roles ARRAY := ARRAY_CONSTRUCT('DBT_DEV_ROLE', 'DBT_TEST_ROLE', 'DBT_PROD_ROLE');
    LET arr_tables ARRAY := ARRAY_CONSTRUCT('BOOKINGS', 'HOSTS', 'LISTINGS');
    LET debug_mode BOOLEAN := FALSE; -- for debug purpose
    LET current_section VARCHAR := ''; -- for debug purpose

    -- =========================================================================
    -- SECTION 1: CREATE DATABASES
    -- =========================================================================
    current_section := 'SECTION 1'; -- for debug purpose

    FOR i IN 0 TO ARRAY_SIZE(:arr_databases) - 1 DO
        LET db VARCHAR := :arr_databases[i];
        LET sql_stmt VARCHAR := 'CREATE DATABASE IF NOT EXISTS ' || :db;
        IF (:debug_mode) THEN
            INSERT INTO DB_AIRBNB_DEBUG.PUBLIC.SECTION_DEBUG (section, object_name, ddl) VALUES (:current_section, :db, :sql_stmt);
        ELSE
            EXECUTE IMMEDIATE :sql_stmt;
        END IF;
    END FOR;

    -- =========================================================================
    -- SECTION 2: CREATE ROLES, ASSIGN TO USER, AND ESTABLISH ROLE HIERARCHY
    -- =========================================================================
    current_section := 'SECTION 2'; -- for debug purpose

    FOR i IN 0 TO ARRAY_SIZE(:arr_roles) - 1 DO
        LET role_name VARCHAR := :arr_roles[i];
        LET sql_stmt VARCHAR := 'CREATE ROLE IF NOT EXISTS ' || :role_name;
        IF (:debug_mode) THEN
            INSERT INTO DB_AIRBNB_DEBUG.PUBLIC.SECTION_DEBUG (section, object_name, ddl) VALUES (:current_section, :role_name, :sql_stmt);
        ELSE
            EXECUTE IMMEDIATE :sql_stmt;
            EXECUTE IMMEDIATE 'GRANT ROLE ' || :role_name || ' TO USER SHREE';
            EXECUTE IMMEDIATE 'GRANT ROLE ' || :role_name || ' TO ROLE SYSADMIN';
        END IF;
    END FOR;

    -- =========================================================================
    -- SECTION 3: CREATE SCHEMAS IN ALL DATABASES
    -- =========================================================================
    current_section := 'SECTION 3'; -- for debug purpose

    FOR i IN 0 TO ARRAY_SIZE(:arr_databases) - 1 DO
        LET db VARCHAR := :arr_databases[i];

        IF (:db = 'DB_AIRBNB_RAW') THEN
            LET sch VARCHAR := :arr_schemas[0];
            LET obj_name VARCHAR := :db || '.' || :sch;
            LET sql_stmt VARCHAR := 'CREATE SCHEMA IF NOT EXISTS ' || :obj_name; 
            IF (:debug_mode) THEN
                INSERT INTO DB_AIRBNB_DEBUG.PUBLIC.SECTION_DEBUG (section, object_name, ddl) VALUES (:current_section, :obj_name, :sql_stmt);
            ELSE
                EXECUTE IMMEDIATE :sql_stmt;
            END IF;
        ELSE
            FOR j IN 1 TO ARRAY_SIZE(:arr_schemas) - 1 DO
                LET sch VARCHAR := :arr_schemas[j];
                LET obj_name VARCHAR := :db || '.' || :sch;
                LET sql_stmt VARCHAR := 'CREATE SCHEMA IF NOT EXISTS ' || :obj_name;  
                IF (:debug_mode) THEN
                    INSERT INTO DB_AIRBNB_DEBUG.PUBLIC.SECTION_DEBUG (section, object_name, ddl) VALUES (:current_section, :obj_name, :sql_stmt);
                ELSE
                    EXECUTE IMMEDIATE :sql_stmt;
                END IF;
            END FOR;
        END IF;
        
    END FOR;

    -- =========================================================================
    -- SECTION 4: CREATE TABLES (RAW ONLY - INGESTION LAYER)
    -- TODO: Read the .csv file header and dynamically build ddl statements for tables
    -- =========================================================================
    current_section := 'SECTION 4'; -- for debug purpose

    FOR i IN 0 TO ARRAY_SIZE(:arr_databases) - 1 DO
        LET db VARCHAR := :arr_databases[i];

        IF (:db = 'DB_AIRBNB_RAW') THEN
            LET schema_name VARCHAR := 'STAGING';
            
            -- ============================================================
            -- HOSTS TABLE
            -- ============================================================

            EXECUTE IMMEDIATE '
            CREATE TABLE IF NOT EXISTS ' || :db || '.' || :schema_name || '.HOSTS (
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
            CREATE TABLE IF NOT EXISTS ' || :db || '.' || :schema_name || '.LISTINGS (
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
            CREATE TABLE IF NOT EXISTS ' || :db || '.' || :schema_name || '.BOOKINGS (
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
        END IF;
    END FOR;

    -- =========================================================================
    -- SECTION 5: FILE FORMATS IN DB_AIRBNB_RAW.STAGING SCHEMA only
    -- =========================================================================
    current_section := 'SECTION 5'; -- for debug purpose

    FOR i IN 0 TO ARRAY_SIZE(:arr_databases) - 1 DO
        LET db VARCHAR := :arr_databases[i];

        IF (:db = 'DB_AIRBNB_RAW') THEN
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
        END IF;
    END FOR;

    -- =========================================================================
    -- SECTION 6: STORAGE INTEGRATION (single shared resource)
    -- NOTE: STORAGE_AWS_ROLE_ARN must be updated per AWS account.
    --       After creation, run DESCRIBE INTEGRATION IO_AIRBNB to get the
    --       STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID values
    --       needed to configure the IAM trust policy in AWS.
    -- =========================================================================
    current_section := 'SECTION 6'; -- for debug purpose

    EXECUTE IMMEDIATE '
        CREATE STORAGE INTEGRATION IF NOT EXISTS IO_AIRBNB
            TYPE = EXTERNAL_STAGE
            STORAGE_PROVIDER = ''S3''
            ENABLED = TRUE
            STORAGE_AWS_ROLE_ARN = ''arn:aws:iam::125206151949:role/SnowflakePipeline''
            STORAGE_ALLOWED_LOCATIONS = (''s3://ppairbnb1/source/'')
            COMMENT = ''Integration to access ppairbnb1 S3 bucket for Airbnb data''';

    -- =========================================================================
    -- SECTION 7: EXTERNAL STAGE (RAW ONLY)
    -- =========================================================================
    current_section := 'SECTION 7'; -- for debug purpose

    FOR i IN 0 TO ARRAY_SIZE(:arr_databases) - 1 DO
        LET db VARCHAR := :arr_databases[i];

        IF (:db = 'DB_AIRBNB_RAW') THEN
            EXECUTE IMMEDIATE '
            CREATE STAGE IF NOT EXISTS ' || :db || '.STAGING.STG_AIRBNB_S3
                STORAGE_INTEGRATION = IO_AIRBNB
                URL = ''s3://ppairbnb1/source/''
                FILE_FORMAT = ' || :db || '.STAGING.CSV_FORMAT
            ';

            EXECUTE IMMEDIATE '
            ALTER STAGE ' || :db || '.STAGING.STG_AIRBNB_S3
            SET DIRECTORY = (ENABLE = TRUE)
            ';
        END IF;
    END FOR;

    
    -- =============================================================================
    -- SECTION 8: CREATE SNOWPIPE
    -- Pipes are created only for raw database
    -- =============================================================================
    current_section := 'SECTION 8'; -- for debug purpose

    FOR i IN 0 TO ARRAY_SIZE(:arr_databases) - 1 DO
        LET db VARCHAR := :arr_databases[i];

        FOR j IN 0 to ARRAY_SIZE(:arr_schemas) -1 DO
            LET sch VARCHAR := :arr_schemas[j];

            IF (:db = 'DB_AIRBNB_RAW' AND :sch = 'STAGING') THEN
            
                FOR k IN 0 TO ARRAY_SIZE(:arr_tables) - 1 DO
                    LET pipename VARCHAR := :arr_tables[k];
                    LET tablename VARCHAR := :arr_tables[k];
                    LET filenamepattern VARCHAR := '.*' || LOWER(:arr_tables[k]) || '.*[.]csv';
                  

    
                    LET sql_stmt VARCHAR := '
                        CREATE PIPE IF NOT EXISTS ' || :db || '.' || :sch || '.' || :pipename || '_PIPE
                            AUTO_INGEST = TRUE
                            AS
                            COPY INTO ' || :db || '.' || :sch || '.' || :tablename || '
                            FROM @' || :db || '.' || :sch || '.STG_AIRBNB_S3
                            PATTERN = ''' || :filenamepattern || '''
                            FILE_FORMAT = (FORMAT_NAME = ' || :db || '.' || :sch || '.CSV_FORMAT_HEADER_METADATA)
                            MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
                            INCLUDE_METADATA = (
                                FILENAME = METADATA$FILENAME,
                                FILE_ROW_NUMBER = METADATA$FILE_ROW_NUMBER,
                                FILE_CONTENT_KEY = METADATA$FILE_CONTENT_KEY,
                                FILE_LAST_MODIFIED = METADATA$FILE_LAST_MODIFIED,
                                START_SCAN_TIME = METADATA$START_SCAN_TIME
                            )';
    
                    IF (:debug_mode) THEN
                        LET pipe_label VARCHAR := :tablename || '_PIPE';
                        INSERT INTO DB_AIRBNB_DEBUG.PUBLIC.SECTION_DEBUG (section, object_name, ddl) VALUES (:current_section, :pipe_label, :sql_stmt);
                    ELSE
                        EXECUTE IMMEDIATE :sql_stmt;
                    END IF;
                END FOR;
            END IF;
        END FOR;
    END FOR;

    -- =========================================================================
    -- SECTION 9: ALL GRANTS (looped over database-role pairs)
    -- =========================================================================
    current_section := 'SECTION 9'; -- for debug purpose

    LET shared_db VARCHAR := :arr_databases[0];
    LET arr_privileges ARRAY := ARRAY_CONSTRUCT('MONITOR', 'OPERATE');

    FOR i IN 0 TO ARRAY_SIZE(:arr_roles) - 1 DO
        LET role_name VARCHAR := :arr_roles[i];
        LET own_db VARCHAR := :arr_databases[i + 1];

        -- =================================================================
        -- SHARED ACCESS: DB_AIRBNB_RAW (full database) for all roles
        -- =================================================================

        -- Permissions on Warehouse
        EXECUTE IMMEDIATE 'GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ' || :role_name;

        -- Permissions on Database & schemas
        EXECUTE IMMEDIATE 'GRANT USAGE ON DATABASE ' || :shared_db || ' TO ROLE ' || :role_name;
        EXECUTE IMMEDIATE 'GRANT USAGE ON ALL SCHEMAS IN DATABASE ' || :shared_db || ' TO ROLE ' || :role_name;
        EXECUTE IMMEDIATE 'GRANT USAGE ON FUTURE SCHEMAS IN DATABASE ' || :shared_db || ' TO ROLE ' || :role_name;

        -- Permissions on Tables
        EXECUTE IMMEDIATE 'GRANT SELECT ON ALL TABLES IN DATABASE ' || :shared_db || ' TO ROLE ' || :role_name;
        EXECUTE IMMEDIATE 'GRANT SELECT ON FUTURE TABLES IN DATABASE ' || :shared_db || ' TO ROLE ' || :role_name;

        -- Stage
        EXECUTE IMMEDIATE 'GRANT USAGE ON STAGE ' || :shared_db || '.' || :arr_schemas[0] || '.STG_AIRBNB_S3 TO ROLE ' || :role_name;

        --  Permissions on File formats
        EXECUTE IMMEDIATE 'GRANT USAGE ON FILE FORMAT ' || :shared_db || '.' || :arr_schemas[0] || '.CSV_FORMAT TO ROLE ' || :role_name;
        EXECUTE IMMEDIATE 'GRANT USAGE ON FILE FORMAT ' || :shared_db || '.' || :arr_schemas[0] || '.CSV_FORMAT_HEADER_METADATA TO ROLE ' || :role_name;

        -- Permissions on Integration
        EXECUTE IMMEDIATE 'GRANT USAGE ON INTEGRATION IO_AIRBNB TO ROLE ' || :role_name;

        -- Permissions on Pipes (MONITOR, OPERATE)
        FOR k IN 0 TO ARRAY_SIZE(:arr_tables) - 1 DO
            LET pipe_name VARCHAR := :shared_db || '.' || :arr_schemas[0] || '.' || :arr_tables[k] || '_PIPE';
            FOR p IN 0 TO ARRAY_SIZE(:arr_privileges) - 1 DO
                EXECUTE IMMEDIATE 'GRANT ' || :arr_privileges[p] || ' ON PIPE ' || :pipe_name || ' TO ROLE ' || :role_name;
            END FOR;
        END FOR;

        -- =================================================================
        -- OWN DATABASE: each role gets full access to its mapped database
        -- =================================================================

        -- Permissions on Database
        EXECUTE IMMEDIATE 'GRANT USAGE ON DATABASE ' || :own_db || ' TO ROLE ' || :role_name;
        EXECUTE IMMEDIATE 'GRANT CREATE SCHEMA ON DATABASE ' || :own_db || ' TO ROLE ' || :role_name;

        -- Permissions on Schemas (current & future)
        EXECUTE IMMEDIATE 'GRANT USAGE ON ALL SCHEMAS IN DATABASE ' || :own_db || ' TO ROLE ' || :role_name;
        EXECUTE IMMEDIATE 'GRANT USAGE ON FUTURE SCHEMAS IN DATABASE ' || :own_db || ' TO ROLE ' || :role_name;
        EXECUTE IMMEDIATE 'GRANT CREATE TABLE ON FUTURE SCHEMAS IN DATABASE ' || :own_db || ' TO ROLE ' || :role_name;
        EXECUTE IMMEDIATE 'GRANT CREATE VIEW ON FUTURE SCHEMAS IN DATABASE ' || :own_db || ' TO ROLE ' || :role_name;

        -- Permissions on Per-schema grants (BRONZE, SILVER, GOLD)
        FOR j IN 1 TO ARRAY_SIZE(:arr_schemas) - 1 DO
            LET sch VARCHAR := :arr_schemas[j];
            EXECUTE IMMEDIATE 'GRANT USAGE ON SCHEMA ' || :own_db || '.' || :sch || ' TO ROLE ' || :role_name;
            EXECUTE IMMEDIATE 'GRANT CREATE TABLE ON SCHEMA ' || :own_db || '.' || :sch || ' TO ROLE ' || :role_name;
            EXECUTE IMMEDIATE 'GRANT CREATE VIEW ON SCHEMA ' || :own_db || '.' || :sch || ' TO ROLE ' || :role_name;
            EXECUTE IMMEDIATE 'GRANT CREATE STAGE ON SCHEMA ' || :own_db || '.' || :sch || ' TO ROLE ' || :role_name;
            EXECUTE IMMEDIATE 'GRANT SELECT ON ALL TABLES IN SCHEMA ' || :own_db || '.' || :sch || ' TO ROLE ' || :role_name;
            EXECUTE IMMEDIATE 'GRANT SELECT ON FUTURE TABLES IN SCHEMA ' || :own_db || '.' || :sch || ' TO ROLE ' || :role_name;
        END FOR;
    END FOR;

    -- =================================================================
    -- SYSADMIN: full access across all databases
    -- =================================================================
    FOR i IN 0 TO ARRAY_SIZE(:arr_databases) - 1 DO
        LET db VARCHAR := :arr_databases[i];

        -- Database
        EXECUTE IMMEDIATE 'GRANT USAGE ON DATABASE ' || :db || ' TO ROLE SYSADMIN';

        IF (:db = :shared_db) THEN
            -- STAGING schema
            EXECUTE IMMEDIATE 'GRANT USAGE ON SCHEMA ' || :db || '.' || :arr_schemas[0] || ' TO ROLE SYSADMIN';
            EXECUTE IMMEDIATE 'GRANT ALL ON SCHEMA ' || :db || '.' || :arr_schemas[0] || ' TO ROLE SYSADMIN';
        ELSE
            -- BRONZE, SILVER, GOLD schemas
            FOR j IN 1 TO ARRAY_SIZE(:arr_schemas) - 1 DO
                LET sch VARCHAR := :arr_schemas[j];
                EXECUTE IMMEDIATE 'GRANT USAGE ON SCHEMA ' || :db || '.' || :sch || ' TO ROLE SYSADMIN';
                EXECUTE IMMEDIATE 'GRANT ALL ON SCHEMA ' || :db || '.' || :sch || ' TO ROLE SYSADMIN';
            END FOR;
        END IF;
    END FOR;

    -- Integration
    EXECUTE IMMEDIATE 'GRANT USAGE ON INTEGRATION IO_AIRBNB TO ROLE SYSADMIN';



    
EXCEPTION
    WHEN OTHER THEN
        LET err_msg VARCHAR := SQLERRM;
        RAISE;
END;

-- =============================================================================
-- VERIFICATION (run separately after the block completes)
-- =============================================================================
-- When debug_mode = TRUE, inspect all or filter by section:
-- SELECT * FROM DB_AIRBNB_DEBUG.PUBLIC.SECTION_DEBUG;
-- SELECT * FROM DB_AIRBNB_DEBUG.PUBLIC.SECTION_DEBUG WHERE section = 'SECTION 9';

/*
SHOW GRANTS TO ROLE dbt_dev_role;
SHOW GRANTS TO ROLE dbt_test_role;
SHOW GRANTS TO ROLE dbt_prod_role;

DESCRIBE STORAGE INTEGRATION IO_AIRBNB;
*/






