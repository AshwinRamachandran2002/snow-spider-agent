WITH trips_2017 AS (
    SELECT
        MONTH( TO_TIMESTAMP_NTZ("end_date" / 1000000) )                          AS month_num,
        "subscriber_type",
        "duration_sec"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS
    WHERE YEAR( TO_TIMESTAMP_NTZ("end_date" / 1000000) ) = 2017
),
monthly_totals AS (
    SELECT
        month_num,
        SUM( CASE WHEN "subscriber_type" = 'Customer'   THEN "duration_sec" ELSE 0 END ) / 60.0 AS minutes_customer,
        SUM( CASE WHEN "subscriber_type" = 'Subscriber' THEN "duration_sec" ELSE 0 END ) / 60.0 AS minutes_subscriber
    FROM trips_2017
    GROUP BY month_num
)
SELECT
    month_num                                                        AS month_with_max_difference
FROM monthly_totals
ORDER BY ABS(minutes_customer - minutes_subscriber) DESC NULLS LAST
LIMIT 1;