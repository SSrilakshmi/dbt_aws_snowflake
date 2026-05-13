{{ config (
        materialized = 'incremental', 
        unique_key = 'host_id'
    ) 
}}

select 
    host_id, 
    replace(host_name, ' ', '') as host_name,
    host_since,
    is_superhost,
    response_rate,
    case 
        when response_rate > 95 then 'Very Good'    
        when response_rate > 80 then 'Good'
        when response_rate > 60 then 'Fair'     
        else 'Poor'
    end as response_quality,
    created_at 
from {{ ref('bronze_hosts') }}
