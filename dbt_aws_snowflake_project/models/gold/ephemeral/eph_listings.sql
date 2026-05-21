{{ config(
    materialized='ephemeral'
)
}}

select
    listing_id,
    property_type,
    room_type,
    price_segment,
    listing_created_at
from {{ ref('onebigtable') }}


{# booking_id, listing_id, host_id, total_price, created_at, nights_booked, 

booking_year, booking_month, booking_day, booking_quarter, is_long_stay, booking_week, booking_dayname,  accommodates, bathrooms, bedrooms,  city, country, price_per_night,  response_rate

sil_l.host_id,  sil_l.accommodates, sil_l.bathrooms, sil_l.bedrooms,  sil_l.city, sil_l.country, sil_l.price_per_night, sil_l.created_at as listing_created_at #}