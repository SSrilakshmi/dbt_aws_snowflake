{{ config(
    materialized='incremental',
    unique_key='error_id',
    on_schema_change='sync_all_columns'
) }}

-- ============================================================================
-- BOOKINGS ERRORS
-- ============================================================================

SELECT
    MD5('BOOKINGS' || FILE_ROW_NUMBER || FILENAME) AS error_id,
    'BOOKINGS' AS source_table,

    CASE
        WHEN booking_id IS NULL THEN 'BOOKING_ID is NULL'
        WHEN TRY_TO_NUMBER(price) IS NULL THEN 'PRICE is not numeric'
        WHEN TRY_TO_DATE(booking_date) IS NULL THEN 'BOOKING_DATE is invalid'
    END AS error_message,

    filename,
    file_row_number,
    TO_JSON(OBJECT_CONSTRUCT(*)) AS rejected_record,
    CURRENT_TIMESTAMP() AS logged_at

FROM {{ ref('bronze_bookings') }}

WHERE booking_id IS NULL
   OR TRY_TO_NUMBER(price) IS NULL
   OR TRY_TO_DATE(booking_date) IS NULL

UNION ALL

-- ============================================================================
-- HOST ERRORS
-- ============================================================================

SELECT
    MD5('HOSTS' || FILE_ROW_NUMBER || FILENAME) AS error_id,
    'HOSTS' AS source_table,

    CASE
        WHEN host_id IS NULL THEN 'HOST_ID is NULL'
        WHEN host_name IS NULL THEN 'HOST_NAME is NULL'
    END AS error_message,

    filename,
    file_row_number,
    TO_JSON(OBJECT_CONSTRUCT(*)) AS rejected_record,
    CURRENT_TIMESTAMP() AS logged_at

FROM {{ ref('bronze_hosts') }}

WHERE host_id IS NULL
   OR host_name IS NULL

UNION ALL

-- ============================================================================
-- LISTING ERRORS
-- ============================================================================

SELECT
    MD5('LISTINGS' || FILE_ROW_NUMBER || FILENAME) AS error_id,
    'LISTINGS' AS source_table,

    CASE
        WHEN listing_id IS NULL THEN 'LISTING_ID is NULL'
        WHEN TRY_TO_NUMBER(price) IS NULL THEN 'PRICE is not numeric'
    END AS error_message,

    filename,
    file_row_number,
    TO_JSON(OBJECT_CONSTRUCT(*)) AS rejected_record,
    CURRENT_TIMESTAMP() AS logged_at

FROM {{ ref('bronze_listings') }}

WHERE listing_id IS NULL
   OR TRY_TO_NUMBER(price) IS NULL

{% if is_incremental() %}
    AND CURRENT_TIMESTAMP() >
        (SELECT COALESCE(MAX(logged_at),'1900-01-01') FROM {{ this }})
{% endif %}