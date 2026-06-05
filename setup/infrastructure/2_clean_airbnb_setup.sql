

--=======
-- drop all databases created in setup
--=======

BEGIN

LET arr_databases ARRAY := ARRAY_CONSTRUCT('DB_AIRBNB_RAW', 'DB_AIRBNB_DEV', 'DB_AIRBNB_TEST', 'DB_AIRBNB', 'DB_AIRBNB_DEBUG');

FOR i IN 0 TO ARRAY_SIZE(:arr_databases) - 1 DO
    EXECUTE IMMEDIATE 'DROP DATABASE IF EXISTS ' || :arr_databases[i];
END FOR;

END;

--=======
-- drop all pipe objects
--=======

BEGIN

LET res RESULTSET := (EXECUTE IMMEDIATE 'SHOW PIPES IN SCHEMA DB_AIRBNB_RAW.STAGING');
LET c CURSOR FOR SELECT "name" AS pipe_name FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

FOR rec IN c DO
    EXECUTE IMMEDIATE
        'DROP PIPE IF EXISTS DB_AIRBNB_RAW.STAGING.' || rec.pipe_name;
END FOR;

END;

