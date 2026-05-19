{% set configs = 
    [
        { "table": "db_airbnb.silver.silver_bookings",
            "columns": "sil_b.*",
            "alias": "sil_b"
        },
        { "table": "db_airbnb.silver.silver_listings",
            "columns": "sil_l.host_id, sil_l.property_type, sil_l.room_type, sil_l.accommodates, sil_l.bathrooms, sil_l.bedrooms, sil_l.bedroom_size, sil_l.city, sil_l.country, sil_l.price_per_night,sil_l.price_segment, sil_l.created_at as listing_created_at ",
            "alias": "sil_l",
            "join_condition": "sil_b.listing_id = sil_l.listing_id"
        },
        {
            "table": "db_airbnb.silver.silver_hosts",
            "columns": "sil_h.host_name, sil_h.host_since, sil_h.is_superhost, sil_h.response_rate, sil_h.response_quality",
            "alias": "sil_h",
            "join_condition": "sil_l.host_id = sil_h.host_id"
        }

    ]
%} 

-- This model creates a one big table in the gold layer by joining the silver tables together.
-- Dynamic SQL is used to loop through the configs and construct the SQL query.
-- The resulting table will have all the columns from the three tables, and can be used for analysis and reporting.


    select 
    {% for config in configs %}
        {{ config.columns }}{% if not loop.last %}, {% endif %}
    {% endfor %}
    from {{ configs[0].table }} as {{ configs[0].alias }}
    {% for config in configs[1:] %}
        left join {{ config.table }} as {{ config.alias }} on {{ config.join_condition }}
    {% endfor %}
