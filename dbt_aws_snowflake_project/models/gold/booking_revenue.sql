
WITH bookings AS (

    SELECT *
    FROM {{ ref('silver_bookings') }}

)


SELECT

    listing_id,

    -- Confirmed revenue
    SUM(
        CASE
            WHEN booking_status = 'Confirmed'
                THEN total_price
            ELSE 0
        END
    ) AS confirmed_revenue,

    -- Cancelled revenue
    SUM(
        CASE
            WHEN booking_status = 'Cancelled'
                THEN total_price
            ELSE 0
        END
    ) AS cancelled_revenue,

    -- Confirmed booking count
    COUNT(
        CASE
            WHEN booking_status = 'Confirmed'
                THEN 1
        END
    ) AS confirmed_bookings,

    -- Cancelled booking count
    COUNT(
        CASE
            WHEN booking_status = 'Cancelled'
                THEN 1
        END
    ) AS cancelled_bookings,

    -- Cancellation rate
    ROUND(
        COUNT(
            CASE
                WHEN booking_status = 'Cancelled'
                    THEN 1
            END
        )
        /
        NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate,

    -- Long stay confirmed revenue
    SUM(
        CASE
            WHEN booking_status = 'Confirmed'
                 AND is_long_stay = TRUE
                THEN total_price
            ELSE 0
        END
    ) AS long_stay_confirmed_revenue,

    -- Optional metrics
    AVG(total_price)::number(10,2) AS avg_booking_value,

    AVG(nights_booked)::number(10,2) AS avg_nights_booked,

    MIN(booking_date) AS first_booking_date,

    MAX(booking_date) AS last_booking_date

FROM bookings
GROUP BY listing_id

-- TODO Add host, city, country from listing and host table