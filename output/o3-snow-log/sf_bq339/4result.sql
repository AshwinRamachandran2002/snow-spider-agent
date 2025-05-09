WITH trips_2017 AS (
    SELECT
        EXTRACT(month FROM TO_TIMESTAMP("end_date" / 1000000))          AS month_num,
        "subscriber_type",
        SUM("duration_sec")                                            AS total_sec
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS
    WHERE EXTRACT(year FROM TO_TIMESTAMP("end_date" / 1000000)) = 2017
      AND "subscriber_type" IN ('Customer','Subscriber')
    GROUP BY month_num, "subscriber_type"
),
monthly_totals AS (
    SELECT
        month_num,
        SUM(CASE WHEN "subscriber_type" = 'Customer'   THEN total_sec ELSE 0 END) AS customer_sec,
        SUM(CASE WHEN "subscriber_type" = 'Subscriber' THEN total_sec ELSE 0 END) AS subscriber_sec
    FROM trips_2017
    GROUP BY month_num
),
monthly_diff AS (
    SELECT
        month_num,
        ABS(customer_sec - subscriber_sec) / 60.0 / 1000  AS diff_thousand_minutes  -- convert seconds ➔ minutes ➔ thousands
    FROM monthly_totals
)
SELECT month_num
FROM monthly_diff
ORDER BY diff_thousand_minutes DESC NULLS LAST
LIMIT 1;