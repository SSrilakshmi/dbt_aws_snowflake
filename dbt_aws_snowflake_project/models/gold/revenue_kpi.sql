WITH bookings AS (

    SELECT *
    FROM {{ ref('silver_bookings') }}

)

SELECT 
    booking_year,
    booking_month,
    count(*) AS gross_bookings,
    count_if(booking_status in ('Confirmed', 'Completed')) as successful_bookings,
    sum(total_price + service_fee + cleaning_fee) as gross_revenue,
    round(sum(total_price + service_fee + cleaning_fee) / count_if(booking_status in ('Confirmed', 'Completed')), 2) as avg_booking_value,
    round(100 * count_if(booking_status = 'Cancelled') / nullif(count(*), 0), 2) as cancellation_rate,
    round(100 * count_if(is_long_stay = TRUE) / nullif(count_if(booking_status in ('Confirmed', 'Completed')), 0), 2) as pct_long_stay,
    round(avg(nights_booked), 2) as avg_nights_booked,
    round(sum(total_price + service_fee + cleaning_fee) / sum(nights_booked), 2) as revenue_per_night
from bookings
group by booking_year, booking_month