WITH trips_2017 AS (
    SELECT
        MONTH(TO_TIMESTAMP("end_date" / 1000000))                         AS month_num ,
        "subscriber_type"                                                AS sub_type ,
        SUM("duration_sec") / 60.0                                       AS minutes          -- convert seconds to minutes
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS
    WHERE YEAR(TO_TIMESTAMP("end_date" / 1000000)) = 2017
      AND "subscriber_type" IN ('Customer','Subscriber')
    GROUP BY month_num , sub_type
),
pivoted AS (
    SELECT
        month_num ,
        SUM(CASE WHEN sub_type = 'Customer'   THEN minutes ELSE 0 END)   AS customer_minutes ,
        SUM(CASE WHEN sub_type = 'Subscriber' THEN minutes ELSE 0 END)   AS subscriber_minutes
    FROM trips_2017
    GROUP BY month_num
),
diffs AS (
    SELECT
        month_num ,
        ABS(customer_minutes - subscriber_minutes) / 1000.0              AS diff_thousand_minutes
    FROM pivoted
)
SELECT month_num
FROM diffs
ORDER BY diff_thousand_minutes DESC NULLS LAST
LIMIT 1;