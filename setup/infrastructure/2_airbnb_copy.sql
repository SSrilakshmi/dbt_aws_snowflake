-- =============================================================================
-- DATA LOADING - Copy data from S3 stage into staging tables
-- Purpose: Load raw CSV data from external stage with metadata tracking
-- Run as: ACCOUNTADMIN (maintains consistent access to temp tables and all objects)
-- Depends on: airbnb_setup.sql (all setup and grants must be complete)
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE DB_AIRBNB_DEV.STAGING;

-- =============================================================================
-- SECTION 1: DEBUG LOG TABLE (created under ACCOUNTADMIN for consistent access)
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE load_log (
    ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    database_name STRING,
    table_name STRING,
    file_name STRING,
    status STRING,
    error_message STRING
);

-- =============================================================================
-- SECTION 2: COPY DATA (looped over databases and tables)
-- Runs as ACCOUNTADMIN to avoid temp table access issues across role switches
-- =============================================================================
BEGIN
    LET databases ARRAY := ARRAY_CONSTRUCT('DB_AIRBNB_DEV', 'DB_AIRBNB_TEST', 'DB_AIRBNB');
    LET tables ARRAY := ARRAY_CONSTRUCT('HOSTS', 'BOOKINGS', 'LISTINGS');
    LET files ARRAY := ARRAY_CONSTRUCT('hosts.csv', 'bookings.csv', 'listings.csv');

    FOR i IN 0 TO ARRAY_SIZE(:databases) - 1 DO
        LET db VARCHAR := :databases[:i];

        FOR j IN 0 TO ARRAY_SIZE(:tables) - 1 DO
            LET tbl VARCHAR := :tables[:j];
            LET f VARCHAR := :files[:j];

            -- Log start of each iteration
            EXECUTE IMMEDIATE '
                INSERT INTO load_log (database_name, table_name, file_name, status)
                VALUES (''' || :db || ''', ''' || :tbl || ''', ''' || :f || ''', ''STARTED'')';

            -- Execute COPY with error handling per table
            BEGIN
                EXECUTE IMMEDIATE '
                    COPY INTO ' || :db || '.STAGING.' || :tbl || '
                      FROM @' || :db || '.STAGING.STG_AIRBNB_S3
                      FILES = (''' || :f || ''')
                      FILE_FORMAT = (FORMAT_NAME = ''' || :db || '.STAGING.CSV_FORMAT_HEADER_METADATA'')
                      ON_ERROR = ABORT_STATEMENT
                      MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
                      INCLUDE_METADATA = (
                        FILENAME = METADATA$FILENAME,
                        FILE_ROW_NUMBER = METADATA$FILE_ROW_NUMBER,
                        FILE_CONTENT_KEY = METADATA$FILE_CONTENT_KEY,
                        FILE_LAST_MODIFIED = METADATA$FILE_LAST_MODIFIED,
                        START_SCAN_TIME = METADATA$START_SCAN_TIME
                      )';

                -- Log success
                EXECUTE IMMEDIATE '
                    INSERT INTO load_log (database_name, table_name, file_name, status)
                    VALUES (''' || :db || ''', ''' || :tbl || ''', ''' || :f || ''', ''COMPLETED'')';

            EXCEPTION
                WHEN OTHER THEN
                    LET err_msg VARCHAR := SQLERRM;
                    EXECUTE IMMEDIATE '
                        INSERT INTO load_log (database_name, table_name, file_name, status, error_message)
                        VALUES (''' || :db || ''', ''' || :tbl || ''', ''' || :f || ''', ''FAILED'', ''' || REPLACE(:err_msg, '''', '''''') || ''')';
            END;
        END FOR;
    END FOR;
END;

-- =============================================================================
-- SECTION 3: DEBUG - VIEW LOAD LOG
-- =============================================================================
SELECT * FROM load_log ORDER BY ts;

-- =============================================================================
-- SECTION 4: VERIFY ROW COUNTS (all databases, looped)
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE row_counts (database_name STRING, table_name STRING, row_count NUMBER);

BEGIN
    LET databases ARRAY := ARRAY_CONSTRUCT('DB_AIRBNB_DEV', 'DB_AIRBNB_TEST', 'DB_AIRBNB');
    LET tables ARRAY := ARRAY_CONSTRUCT('HOSTS', 'BOOKINGS', 'LISTINGS');

    FOR i IN 0 TO ARRAY_SIZE(:databases) - 1 DO
        LET db VARCHAR := :databases[:i];
        FOR j IN 0 TO ARRAY_SIZE(:tables) - 1 DO
            LET tbl VARCHAR := :tables[:j];
            EXECUTE IMMEDIATE '
                INSERT INTO row_counts
                SELECT ''' || :db || ''', ''' || :tbl || ''', COUNT(*)
                FROM ' || :db || '.STAGING.' || :tbl;
        END FOR;
    END FOR;
END;

SELECT * FROM row_counts ORDER BY database_name, table_name;
one