{% snapshot dim_bookings %}

{{ config(
      target_schema = 'gold',
      unique_key = 'booking_id',
      strategy = 'timestamp',
      updated_at = 'booking_created_at',
      dbt_valid_to_current = "to_date('9999-12-31')" 
      ) 
}}

select * from {{ ref('eph_bookings') }}
{% endsnapshot %}