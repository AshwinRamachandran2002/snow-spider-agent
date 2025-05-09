SELECT
    "Month_Num",
    "Month",
    ROUND("Total_Minutes_Customers", 4) AS "Cumulative_Usage_Minutes_Customers",
    ROUND("Total_Minutes_Subscribers", 4) AS "Cumulative_Usage_Minutes_Subscribers",
    ROUND("Absolute_Difference", 4) AS "Absolute_Difference"
FROM
    (
        SELECT
            MONTH(TO_TIMESTAMP_LTZ("start_date" / 1e6)) AS "Month_Num",
            TO_CHAR(TO_TIMESTAMP_LTZ("start_date" / 1e6), 'Mon') AS "Month",
            SUM(CASE WHEN "subscriber_type" = 'Customer' THEN "duration_sec" ELSE 0 END) / 60 AS "Total_Minutes_Customers",
            SUM(CASE WHEN "subscriber_type" = 'Subscriber' THEN "duration_sec" ELSE 0 END) / 60 AS "Total_Minutes_Subscribers",
            ABS(
                SUM(CASE WHEN "subscriber_type" = 'Customer' THEN "duration_sec" ELSE 0 END) / 60 -
                SUM(CASE WHEN "subscriber_type" = 'Subscriber' THEN "duration_sec" ELSE 0 END) / 60
            ) AS "Absolute_Difference"
        FROM
            "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_TRIPS"
        WHERE
            TO_TIMESTAMP_LTZ("start_date" / 1e6) >= '2017-01-01' AND
            TO_TIMESTAMP_LTZ("start_date" / 1e6) < '2018-01-01' AND
            "subscriber_type" IN ('Customer', 'Subscriber')
        GROUP BY
            "Month_Num",
            "Month"
    ) AS monthly_totals
ORDER BY
    "Absolute_Difference" DESC NULLS LAST, "Month_Num"
LIMIT 1;