WITH daily_precipitation AS (
    SELECT
        "date",
        SUM("value") / 10.0 AS total_precip_mm
    FROM "NEW_YORK_GHCN"."GHCN_D"."GHCND_1764"
    WHERE
        "element" = 'PRCP' 
        AND "qflag" IS NULL 
        AND YEAR("date") = 2016
    GROUP BY "date"
),
daily_trips AS (
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ("starttime" / 1e6)) AS "trip_date",
        COUNT(*) AS "trip_count"
    FROM "NEW_YORK_GHCN"."NEW_YORK"."CITIBIKE_TRIPS"
    WHERE YEAR(TO_TIMESTAMP_NTZ("starttime" / 1e6)) = 2016
    GROUP BY "trip_date"
),
trip_precipitation AS (
    SELECT
        dt."trip_date",
        dt."trip_count",
        COALESCE(dp.total_precip_mm, 0) AS total_precip_mm
    FROM daily_trips dt
    LEFT JOIN daily_precipitation dp
        ON dt."trip_date" = dp."date"
),
trip_weather AS (
    SELECT
        CASE WHEN total_precip_mm > 5 THEN 'Rainy' ELSE 'Non-Rainy' END AS "Weather",
        "trip_count"
    FROM trip_precipitation
)
SELECT
    "Weather",
    ROUND(AVG("trip_count"), 4) AS "Average_Daily_Trips"
FROM trip_weather
GROUP BY "Weather";