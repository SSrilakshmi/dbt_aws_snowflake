{{ config (
        materialized = 'incremental', 
        unique_key = 'listing_id'
    ) 
}}

select 
    listing_id, 
    host_id, 
    property_type, 
    room_type,
    city,
    country,
    {{ tag_occupancy('accommodates') }} as accommodates,
    bedrooms,
    bathrooms,
    price_per_night,
    created_at 
from {{ ref('bronze_listings') }}
