WITH trips_2017 AS (
    SELECT
        TO_TIMESTAMP("end_date" / 1000000)            AS "end_ts",          -- convert µs to TIMESTAMP
        "duration_sec",
        "subscriber_type"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS
    WHERE "end_date" IS NOT NULL
), month_usage AS (
    SELECT
        MONTH("end_ts")                                                                    AS "month_num",
        SUM(CASE WHEN "subscriber_type" = 'Customer'   THEN "duration_sec" / 60.0 ELSE 0 END) AS "customer_minutes",
        SUM(CASE WHEN "subscriber_type" = 'Subscriber' THEN "duration_sec" / 60.0 ELSE 0 END) AS "subscriber_minutes"
    FROM trips_2017
    WHERE YEAR("end_ts") = 2017
    GROUP BY "month_num"
)
SELECT
    "month_num"                                      AS "month",
    ROUND(ABS("customer_minutes" - "subscriber_minutes") / 1000, 4) AS "difference_minutes_k"
FROM month_usage
ORDER BY "difference_minutes_k" DESC NULLS LAST
LIMIT 1;