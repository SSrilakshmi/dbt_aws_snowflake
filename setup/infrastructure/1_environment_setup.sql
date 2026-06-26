/*
=========================================================================
Purpose:    Creates database infrastructure for Airbnb
Dependency: Requires 00_seed_config.sql to be run first
Author:     Shree
=========================================================================
*/

-- Create databases and schemas 
DECLARE
    -- Arrays
    arr_databases   ARRAY DEFAULT 
                    (SELECT ARRAY_AGG(DATABASE_NAME) 
                    FROM DB_AIRBNB_ ADMIN.CONFIG.CONFIG_DATABASES);                    
    arr_schemas     ARRAY DEFAULT 
                    (SELECT ARRAY_AGG(SCHEMA_NAME) 
                     FROM DB_AIRBNB_ADMIN.CONFIG.CONFIG_SCHEMAS);

    -- Variables
    db_name         VARCHAR;
    sch_name        VARCHAR;

    -- Counters
    i               INTEGER;
    j               INTEGER;

BEGIN

    FOR i IN 0 TO ARRAY_SIZE(arr_databases) - 1 DO
        db_name := TRIM(arr_databases[i]::VARCHAR, '"');

        -- Create database for each environment (raw/dev/test/prod)
        EXECUTE IMMEDIATE
            'CREATE DATABASE IF NOT EXISTS ' || db_name;

        FOR j IN 0 TO ARRAY_SIZE(arr_schemas) - 1 DO
            sch_name := TRIM(arr_schemas[j]::VARCHAR, '"');

            -- RAW environment gets STAGING schema only; all others get BRONZE/SILVER/GOLD
            IF (db_name = 'DB_AIRBNB_RAW' AND sch_name = 'STAGING') THEN
                EXECUTE IMMEDIATE
                    'CREATE SCHEMA IF NOT EXISTS ' || db_name || '.' || sch_name;
            ELSEIF (db_name != 'DB_AIRBNB_RAW' AND sch_name != 'STAGING') THEN
                EXECUTE IMMEDIATE
                    'CREATE SCHEMA IF NOT EXISTS ' || db_name || '.' || sch_name;
            END IF;

        END FOR;
    END FOR;

END;

  