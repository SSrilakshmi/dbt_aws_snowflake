{% set configs = 
    [
        { "table": ref('onebigtable'),
            "columns": "gld_obt.booking_id, gld_obt.host_id, gld_obt.listing_id, gld_obt.total_price, gld_obt.service_fee, gld_obt.cleaning_fee, gld_obt.accommodates, gld_obt.bedrooms, gld_obt.bathrooms, gld_obt.nights_booked, gld_obt.price_per_night, gld_obt.response_rate",
            "alias": "gld_obt"
        },
        { "table": ref('silver_listings'),
            "columns": "",
            "alias": "sil_l",
            "join_condition": "gld_obt.listing_id = sil_l.listing_id"
        },
        {
            "table": ref('silver_hosts'),
            "columns": "",
            "alias": "sil_h",
            "join_condition": "sil_l.host_id = sil_h.host_id"
        }

    ]
%} 

-- This model creates a one big table in the gold layer by joining the silver tables together.
-- Dynamic SQL is used to loop through the configs and construct the SQL query.
-- The resulting table will have all the columns from the three tables, and can be used for analysis and reporting.

select 
    {{ configs[0].columns }}
from {{ configs[0].table }} as {{ configs[0].alias }}
{% for config in configs[1:] %}
    left join {{ config.table }} as {{ config.alias }} on {{ config.join_condition }}
{% endfor %}
