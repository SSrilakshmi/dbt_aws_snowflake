{% snapshot dim_hosts %}

{{ config(
      target_schema = 'gold',
      unique_key = 'host_id',
      strategy = 'timestamp',
      updated_at = 'host_created_at',
      dbt_valid_to_current = "to_date('9999-12-31')" 
      ) 
}}

select * from {{ ref('eph_hosts') }}
{% endsnapshot %}