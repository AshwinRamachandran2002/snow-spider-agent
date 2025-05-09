WITH monthly_usage AS (
    SELECT
        EXTRACT(month FROM TO_TIMESTAMP("end_date" / 1000000))               AS month_num,
        "subscriber_type",
        SUM("duration_sec") / 60.0                                           AS total_minutes   -- convert seconds to minutes
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS
    WHERE EXTRACT(year FROM TO_TIMESTAMP("end_date" / 1000000)) = 2017       -- keep only 2017 trips
    GROUP BY month_num, "subscriber_type"
),
pivoted AS (
    SELECT
        month_num,
        COALESCE(MAX(CASE WHEN "subscriber_type" = 'Customer'   THEN total_minutes END), 0) AS customer_minutes,
        COALESCE(MAX(CASE WHEN "subscriber_type" = 'Subscriber' THEN total_minutes END), 0) AS subscriber_minutes
    FROM monthly_usage
    GROUP BY month_num
),
diffs AS (
    SELECT
        month_num,
        ABS(customer_minutes - subscriber_minutes) / 1000.0 AS diff_thousand_minutes
    FROM pivoted
)
SELECT month_num
FROM diffs
ORDER BY diff_thousand_minutes DESC NULLS LAST
LIMIT 1;