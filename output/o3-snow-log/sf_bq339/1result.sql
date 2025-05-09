WITH trips_2017 AS (
    SELECT
        EXTRACT(month FROM TO_TIMESTAMP("end_date" / 1000000))  AS month_num,
        "subscriber_type",
        "duration_sec"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS
    WHERE EXTRACT(year  FROM TO_TIMESTAMP("end_date" / 1000000)) = 2017
), monthly_minutes AS (
    SELECT
        month_num,
        SUM(CASE WHEN "subscriber_type" = 'Customer'   THEN "duration_sec" / 60.0 ELSE 0 END) AS customer_minutes,
        SUM(CASE WHEN "subscriber_type" = 'Subscriber' THEN "duration_sec" / 60.0 ELSE 0 END) AS subscriber_minutes
    FROM trips_2017
    GROUP BY month_num
)
SELECT
    month_num                                            AS month,
    ABS(customer_minutes - subscriber_minutes) / 1000.0 AS diff_minutes_thousands
FROM monthly_minutes
ORDER BY diff_minutes_thousands DESC NULLS LAST
LIMIT 1;