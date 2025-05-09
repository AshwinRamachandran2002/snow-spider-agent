WITH trip_minutes_2017 AS (
    /* convert micro-seconds epoch to timestamp, keep only 2017 trips */
    SELECT
        EXTRACT(month FROM end_ts)                           AS month_num,
        LOWER("subscriber_type")                             AS sub_type,
        SUM("duration_sec") / 60.0                           AS total_minutes      -- minutes
    FROM (
        SELECT
            TO_TIMESTAMP_NTZ("end_date" / 1000000)           AS end_ts,
            "duration_sec",
            "subscriber_type"
        FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS
        WHERE "end_date" IS NOT NULL
    )
    WHERE EXTRACT(year FROM end_ts) = 2017
    GROUP BY month_num, sub_type
),
pivoted AS (
    /* get one row per month with separate totals for customers & subscribers */
    SELECT
        month_num,
        COALESCE(MAX(CASE WHEN sub_type = 'customer'   THEN total_minutes END),0) AS customer_minutes,
        COALESCE(MAX(CASE WHEN sub_type = 'subscriber' THEN total_minutes END),0) AS subscriber_minutes
    FROM trip_minutes_2017
    GROUP BY month_num
),
diffs AS (
    /* absolute difference in thousands of minutes */
    SELECT
        month_num,
        ABS(customer_minutes - subscriber_minutes) / 1000.0 AS diff_thousands
    FROM pivoted
)
SELECT month_num
FROM diffs
ORDER BY diff_thousands DESC NULLS LAST
LIMIT 1;