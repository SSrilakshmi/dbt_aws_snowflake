{% snapshot dim_listings %}

{{ config(
      target_schema = 'gold',
      unique_key = 'listing_id',
      strategy = 'timestamp',
      updated_at = 'listing_created_at',
      dbt_valid_to_current = "to_date('9999-12-31')"     
      ) 
}}

select * from {{ ref('eph_listings') }}
{% endsnapshot %}