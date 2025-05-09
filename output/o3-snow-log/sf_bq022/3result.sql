/* --- 6-quantile statistics for taxi trips ≤ 60 minutes ------------------
   NOTE: A 1 % random SYSTEM sample is used so the query finishes quickly.
-------------------------------------------------------------------------*/
WITH sampled AS (           -- ~1 % random sample of eligible trips
    SELECT
        "trip_seconds",
        "fare",
        ROUND("trip_seconds" / 60.0) AS "trip_minutes"
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    TABLESAMPLE SYSTEM (1)            -- 1 percent sample
    WHERE "trip_seconds" BETWEEN 1 AND 3600
),
bucketed AS (               -- split the sample into six equal-sized groups
    SELECT
        NTILE(6) OVER (ORDER BY "trip_seconds") AS "quantile_group",
        "trip_minutes",
        "fare"
    FROM sampled
)
SELECT
    "quantile_group",
    MIN("trip_minutes") AS "min_trip_minutes",
    MAX("trip_minutes") AS "max_trip_minutes",
    COUNT(*)            AS "total_trips",
    AVG("fare")         AS "avg_fare"
FROM bucketed
GROUP BY "quantile_group"
ORDER BY "quantile_group";