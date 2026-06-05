{{ 
  config(
    severity = 'warn'
    )
}}

select 1 
from {{source('db_airbnb_raw', 'bookings')}}
where booking_amount < 0