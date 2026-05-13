select * from {{ ref('bronze_listings') }}

--select distinct property_type from {{ ref('bronze_listings') }} order by property_type

--select distinct room_type from {{ ref('bronze_listings') }}

--select distinct accommodates from {{ ref('bronze_listings') }}
