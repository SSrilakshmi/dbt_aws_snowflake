{{
  config(
    materialized = 'incremental',
    on_schema_change='sync_all_columns'
    )
}}

select *
from {{ source('db_airbnb_raw', 'bookings') }}
{% if is_incremental() -%}
where created_at > (select coalesce(max(created_at), '1900-01-01') from {{ this }})
{% endif %}
