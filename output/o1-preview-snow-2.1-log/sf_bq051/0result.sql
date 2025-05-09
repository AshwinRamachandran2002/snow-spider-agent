WITH weather AS (
    SELECT
        "date",
        CASE WHEN "value" > 0.5 THEN 'Rainy' ELSE 'Non-Rainy' END AS "Rain_Type"
    FROM
        "NEW_YORK_GHCN"."GHCN_D"."GHCND_2016"
    WHERE
        "id" = 'USW00094728' AND
        "element" = 'PRCP' AND
        "date" BETWEEN '2016-01-01' AND '2016-12-31'
),
trips AS (
    SELECT
        DATE(TO_TIMESTAMP_LTZ("pickup_datetime" / 1e6, 0)) AS "date",
        COUNT(*) AS "trip_count"
    FROM
        "NEW_YORK_GHCN"."NEW_YORK"."TLC_YELLOW_TRIPS_2016"
    WHERE
        "pickup_datetime" >= 1451606400000000 AND
        "pickup_datetime" <= 1483228799000000
    GROUP BY
        DATE(TO_TIMESTAMP_LTZ("pickup_datetime" / 1e6, 0))
)
SELECT
    w."Rain_Type",
    ROUND(AVG(t."trip_count"), 4) AS "Average_Number_of_Trips"
FROM
    trips t
    JOIN weather w ON t."date" = w."date"
GROUP BY
    w."Rain_Type";