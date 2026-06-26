/*
=========================================================================
Dynamic security setup: grants role-based access to databases and all object types
Co-authored with CoCo

Script:     03_security_setup.sql
Purpose:    Dynamically grants roles access to databases, schemas, and
            all object types (tables, views, stages, file formats, pipes,
            streams, functions, procedures, sequences).

Dependency: Requires 01_environment_setup.sql and 02_ingestion_setup.sql
            to have been executed first.

Config:     Reads from DB_AIRBNB_ADMIN.CONFIG.CONFIG_ROLES which defines:
            - ROLE_NAME:     The Snowflake role to receive grants
            - DATABASE_NAME: The database associated with that role

Logic:
  1. WAREHOUSE ACCESS
     All non-ALL roles receive USAGE on COMPUTE_WH.

  2. SHARED DATABASE ACCESS (ROLE_NAME = 'ALL')
     When a row has ROLE_NAME = 'ALL', the associated DATABASE_NAME is
     treated as a shared resource. Every other (non-ALL) role is granted
     read access to ALL existing and FUTURE objects in that database:
       - Schemas (USAGE)
       - Tables, Views, Streams (SELECT)
       - Stages, File Formats, Functions, Procedures, Sequences (USAGE)
       - Pipes (MONITOR)

     Example: If CONFIG_ROLES has (ALL, DB_AIRBNB_RAW), then DBT_DEV_ROLE,
     DBT_TEST_ROLE, DBT_PROD_ROLE all get access to DB_AIRBNB_RAW.

  3. ENVIRONMENT-SPECIFIC ACCESS (ROLE_NAME != 'ALL')
     Each role gets FULL privileges (ALL) on its own database, including
     all current and future schemas and tables.

     Example: DBT_DEV_ROLE gets ALL on DB_AIRBNB_DEV.

Author:     Shree
=========================================================================
*/

DECLARE
    -- Arrays loaded from CONFIG_ROLES
    arr_roles          ARRAY;    -- All ROLE_NAME values
    arr_databases      ARRAY;    -- All DATABASE_NAME values (positionally matched)

    -- Loop variables
    db_name         VARCHAR;    -- Current database being processed
    role_name       VARCHAR;    -- Current role being processed
    shared_db       VARCHAR;    -- Database flagged for shared access (via 'ALL' marker)
    j               INTEGER;    -- Inner loop counter
    other_role      VARCHAR;    -- Role receiving shared grants in inner loop
    pipe_name       VARCHAR;    -- Fully qualified pipe name for individual grants
    pipe_cur        RESULTSET;  -- Cursor for iterating over pipes

    -- Counters
    i               INTEGER;    -- Outer loop counter

BEGIN

    -- =========================================================================
    -- STEP 0: Load configuration
    -- Reads all role-to-database mappings into parallel arrays
    -- =========================================================================
    SELECT ARRAY_AGG(ROLE_NAME), ARRAY_AGG(DATABASE_NAME)
        INTO :arr_roles, :arr_databases
        FROM DB_AIRBNB_ADMIN.CONFIG.CONFIG_ROLES;

    -- =========================================================================
    -- STEP 1: Warehouse access
    -- Every real role (non-ALL) gets USAGE on the shared compute warehouse
    -- =========================================================================
    FOR i IN 0 TO ARRAY_SIZE(arr_roles) - 1 DO
        role_name := TRIM(arr_roles[i]::VARCHAR, '"');
        IF (role_name != 'ALL') THEN
            EXECUTE IMMEDIATE
                'GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ' || role_name;
        END IF;
    END FOR;

    -- =========================================================================
    -- STEP 2: Shared database access
    -- When ROLE_NAME = 'ALL', the associated database is shared with all
    -- other roles. Grants cover ALL existing + FUTURE objects of every type.
    -- =========================================================================
    FOR i IN 0 TO ARRAY_SIZE(arr_roles) - 1 DO
        role_name := TRIM(arr_roles[i]::VARCHAR, '"');

        IF (role_name = 'ALL') THEN
            shared_db := TRIM(arr_databases[i]::VARCHAR, '"');

            -- Grant shared database access to every non-ALL role
            FOR j IN 0 TO ARRAY_SIZE(arr_roles) - 1 DO
                other_role := TRIM(arr_roles[j]::VARCHAR, '"');

                IF (other_role != 'ALL') THEN
                    -- Database & schema usage
                    EXECUTE IMMEDIATE
                        'GRANT USAGE ON DATABASE ' || shared_db || ' TO ROLE ' || other_role;
                    EXECUTE IMMEDIATE
                        'GRANT USAGE ON ALL SCHEMAS IN DATABASE ' || shared_db || ' TO ROLE ' || other_role;
                    EXECUTE IMMEDIATE
                        'GRANT USAGE ON FUTURE SCHEMAS IN DATABASE ' || shared_db || ' TO ROLE ' || other_role;

                    -- Tables
                    EXECUTE IMMEDIATE
                        'GRANT SELECT ON ALL TABLES IN DATABASE ' || shared_db || ' TO ROLE ' || other_role;
                    EXECUTE IMMEDIATE
                        'GRANT SELECT ON FUTURE TABLES IN DATABASE ' || shared_db || ' TO ROLE ' || other_role;

                    -- Views
                    EXECUTE IMMEDIATE
                        'GRANT SELECT ON ALL VIEWS IN DATABASE ' || shared_db || ' TO ROLE ' || other_role;
                    EXECUTE IMMEDIATE
                        'GRANT SELECT ON FUTURE VIEWS IN DATABASE ' || shared_db || ' TO ROLE ' || other_role;

                    -- Stages
                    EXECUTE IMMEDIATE
                        'GRANT USAGE ON ALL STAGES IN DATABASE ' || shared_db || ' TO ROLE ' || other_role;
                    EXECUTE IMMEDIATE
                        'GRANT USAGE ON FUTURE STAGES IN DATABASE ' || shared_db || ' TO ROLE ' || other_role;

                    -- File formats
                    EXECUTE IMMEDIATE
                        'GRANT USAGE ON ALL FILE FORMATS IN DATABASE ' || shared_db || ' TO ROLE ' || other_role;
                    EXECUTE IMMEDIATE
                        'GRANT USAGE ON FUTURE FILE FORMATS IN DATABASE ' || shared_db || ' TO ROLE ' || other_role;

                    -- Pipes (bulk grant restricted; grant individually via SHOW PIPES)
                    EXECUTE IMMEDIATE 'SHOW PIPES IN DATABASE ' || shared_db;
                    pipe_cur := (SELECT "database_name" || '.' || "schema_name" || '.' || "name" AS fqn
                                 FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));
                    FOR rec IN pipe_cur DO
                        pipe_name := rec.fqn;
                        EXECUTE IMMEDIATE
                            'GRANT MONITOR ON PIPE ' || pipe_name || ' TO ROLE ' || other_role;
                    END FOR;

                    -- Streams
                    EXECUTE IMMEDIATE
                        'GRANT SELECT ON ALL STREAMS IN DATABASE ' || shared_db || ' TO ROLE ' || other_role;
                    EXECUTE IMMEDIATE
                        'GRANT SELECT ON FUTURE STREAMS IN DATABASE ' || shared_db || ' TO ROLE ' || other_role;

                    -- Functions & Procedures
                    EXECUTE IMMEDIATE
                        'GRANT USAGE ON ALL FUNCTIONS IN DATABASE ' || shared_db || ' TO ROLE ' || other_role;
                    EXECUTE IMMEDIATE
                        'GRANT USAGE ON FUTURE FUNCTIONS IN DATABASE ' || shared_db || ' TO ROLE ' || other_role;
                    EXECUTE IMMEDIATE
                        'GRANT USAGE ON ALL PROCEDURES IN DATABASE ' || shared_db || ' TO ROLE ' || other_role;
                    EXECUTE IMMEDIATE
                        'GRANT USAGE ON FUTURE PROCEDURES IN DATABASE ' || shared_db || ' TO ROLE ' || other_role;

                    -- Sequences
                    EXECUTE IMMEDIATE
                        'GRANT USAGE ON ALL SEQUENCES IN DATABASE ' || shared_db || ' TO ROLE ' || other_role;
                    EXECUTE IMMEDIATE
                        'GRANT USAGE ON FUTURE SEQUENCES IN DATABASE ' || shared_db || ' TO ROLE ' || other_role;
                END IF;
            END FOR;
        END IF;
    END FOR;

    -- =========================================================================
    -- STEP 3: Environment-specific access
    -- Each non-ALL role gets ALL privileges on its own database (dev/test/prod)
    -- =========================================================================
    FOR i IN 0 TO ARRAY_SIZE(arr_databases) - 1 DO
        db_name   := TRIM(arr_databases[i]::VARCHAR, '"');
        role_name := TRIM(arr_roles[i]::VARCHAR, '"');

        IF (role_name != 'ALL') THEN
            EXECUTE IMMEDIATE
                'GRANT ALL ON DATABASE ' || db_name || ' TO ROLE ' || role_name;
            EXECUTE IMMEDIATE
                'GRANT ALL ON ALL SCHEMAS IN DATABASE ' || db_name || ' TO ROLE ' || role_name;
            EXECUTE IMMEDIATE
                'GRANT ALL ON ALL TABLES IN DATABASE ' || db_name || ' TO ROLE ' || role_name;
            EXECUTE IMMEDIATE
                'GRANT ALL ON FUTURE SCHEMAS IN DATABASE ' || db_name || ' TO ROLE ' || role_name;
            EXECUTE IMMEDIATE
                'GRANT ALL ON FUTURE TABLES IN DATABASE ' || db_name || ' TO ROLE ' || role_name;
        END IF;
    END FOR;

END;