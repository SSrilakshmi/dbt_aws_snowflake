{{ config (
        materialized = 'incremental', 
        unique_key = 'booking_id'
    ) 
}}

select 
    booking_id, 
    listing_id, 
    booking_date, 
    {{multiply('booking_amount', 'nights_booked', 2) }} nights_price,
    service_fee,
     cleaning_fee, 
    booking_status, 
    created_at 
from {{ ref('bronze_bookings') }}
