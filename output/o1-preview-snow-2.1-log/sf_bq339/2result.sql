SELECT
    "month" AS "Month_num",
    CASE
        WHEN "month" = 1 THEN 'January'
        WHEN "month" = 2 THEN 'February'
        WHEN "month" = 3 THEN 'March'
        WHEN "month" = 4 THEN 'April'
        WHEN "month" = 5 THEN 'May'
        WHEN "month" = 6 THEN 'June'
        WHEN "month" = 7 THEN 'July'
        WHEN "month" = 8 THEN 'August'
        WHEN "month" = 9 THEN 'September'
        WHEN "month" = 10 THEN 'October'
        WHEN "month" = 11 THEN 'November'
        WHEN "month" = 12 THEN 'December'
    END AS "Month",
    ROUND("total_minutes_customers", 4) AS "Cumulative_Usage_Minutes_Customers",
    ROUND("total_minutes_subscribers", 4) AS "Cumulative_Usage_Minutes_Subscribers",
    ROUND(ABS("total_minutes_customers" - "total_minutes_subscribers"), 4) AS "Absolute_Difference"
FROM
(
    SELECT
        EXTRACT(MONTH FROM TO_TIMESTAMP("start_date" / 1e6)) AS "month",
        SUM(CASE WHEN "subscriber_type" = 'Customer' THEN "duration_sec" / 60 ELSE 0 END) AS "total_minutes_customers",
        SUM(CASE WHEN "subscriber_type" = 'Subscriber' THEN "duration_sec" / 60 ELSE 0 END) AS "total_minutes_subscribers"
    FROM
        SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS
    WHERE
        EXTRACT(YEAR FROM TO_TIMESTAMP("start_date" / 1e6)) = 2017
    GROUP BY
        "month"
)
ORDER BY
    ABS("total_minutes_customers" - "total_minutes_subscribers") DESC NULLS LAST
LIMIT 1;