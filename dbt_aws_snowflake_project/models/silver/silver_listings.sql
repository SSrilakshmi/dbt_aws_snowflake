{{ config (
        materialized = 'incremental', 
        on_schema_change='sync_all_columns',
        unique_key = 'listing_id'

    ) 
}}

select 
    listing_id, 
    host_id, 
    {{-standardize_text('property_type') }} as property_type,
    {{- standardize_text('room_type') }} as room_type,
    city,
    country,
    {{- tag_occupancy('accommodates') -}} as accommodates,    
    bedrooms,
    case 
        when bedrooms = 1 then 'Small'
        when bedrooms <= 3 then 'Medium'
        else 'Large'
    end as bedroom_size,
    bathrooms,
    price_per_night,
    case 
        when price_per_night < 100 then 'Budget'
        when price_per_night < 200 then 'Standard'
        else 'Luxury'
    end as  price_segment,
    created_at 
from {{ ref('bronze_listings') }}