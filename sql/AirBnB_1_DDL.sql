CREATE OR REPLACE DATABASE db_airbnb;
CREATE OR REPLACE SCHEMA staging;


USE ROLE ACCOUNTADMIN;
GRANT USAGE ON DATABASE db_airbnb TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA db_airbnb.staging TO ROLE SYSADMIN;

/*
  Query: Database Access by Role (no latency)
  Uses SHOW GRANTS which returns real-time data, unlike ACCOUNT_USAGE views (up to 2h latency).
*/
SHOW GRANTS ON DATABASE db_airbnb;
SHOW GRANTS ON SCHEMA db_airbnb.staging;


-- DDL For My Tables
CREATE OR REPLACE TABLE HOSTS (
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
);

CREATE OR REPLACE TABLE LISTINGS (
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
);

CREATE OR REPLACE TABLE BOOKINGS (
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
);

-- check initial counts
SELECT COUNT(*) FROM DB_AIRBNB.STAGING.BOOKINGS;
--0
SELECT COUNT(*) FROM DB_AIRBNB.STAGING.LISTINGS;
--0
SELECT COUNT(*) FROM DB_AIRBNB.STAGING.HOSTS;
--0






  