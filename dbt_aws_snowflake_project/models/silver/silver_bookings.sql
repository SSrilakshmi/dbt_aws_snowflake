{{ config (
        materialized = 'incremental', 
        on_schema_change='sync_all_columns',
        unique_key = 'booking_id'
    ) 
}}

select 
    booking_id, 
    listing_id, 
    booking_date, 
    (
        {{multiply('booking_amount', 'nights_booked', 2) }} 
        + service_fee ::NUMBER(10, 2)
        + cleaning_fee ::NUMBER(10, 2)  
    ) AS total_price,
    
    booking_status, 
    created_at 
from {{ ref('bronze_bookings') }}
