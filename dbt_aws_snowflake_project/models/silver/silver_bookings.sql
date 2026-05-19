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
    year(booking_date) as booking_year,
    month(booking_date) as booking_month,
    day(booking_date) as booking_day,   
    quarter(booking_date) as booking_quarter,
    week(booking_date) as booking_week,
    dayname(booking_date) as booking_dayname,
    (
        {{multiply('booking_amount', 'nights_booked', 2) }} 
        + service_fee ::number(10, 2)
        + cleaning_fee ::number(10, 2)  
    ) as total_price,
    nights_booked,
    service_fee::number(10,2) as service_fee,
    cleaning_fee::number(10,2) as cleaning_fee,    
    case 
        when nights_booked >= 7 then TRUE
        else FALSE
    end as is_long_stay,
    {{-standardize_text('booking_status')}} as booking_status,
    created_at 
from {{ ref('bronze_bookings') }}
