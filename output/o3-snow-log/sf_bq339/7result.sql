WITH trips_2017 AS (
    SELECT
        EXTRACT(month FROM TO_TIMESTAMP("end_date" / 1000000))               AS month_num,
        "subscriber_type",
        ("duration_sec" / 60.0)                                              AS minutes
    FROM   SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS
    WHERE  EXTRACT(year FROM TO_TIMESTAMP("end_date" / 1000000)) = 2017
       AND "subscriber_type" IN ('Customer', 'Subscriber')
),
monthly_totals AS (
    SELECT
        month_num,
        SUM(CASE WHEN "subscriber_type" = 'Customer'   THEN minutes ELSE 0 END) AS customer_minutes,
        SUM(CASE WHEN "subscriber_type" = 'Subscriber' THEN minutes ELSE 0 END) AS subscriber_minutes
    FROM trips_2017
    GROUP BY month_num
),
monthly_diffs AS (
    SELECT
        month_num,
        ABS(customer_minutes - subscriber_minutes) / 1000.0 AS diff_thousands_minutes
    FROM monthly_totals
)
SELECT
    month_num  AS month,
    diff_thousands_minutes
FROM monthly_diffs
ORDER BY diff_thousands_minutes DESC NULLS LAST
LIMIT 1;