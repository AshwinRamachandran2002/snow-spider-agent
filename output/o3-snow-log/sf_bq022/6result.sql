WITH sampled AS (      -- shrink the working set to avoid timeout
    SELECT
        "trip_seconds",
        "fare"
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    TABLESAMPLE BERNOULLI (5)          -- ~5 % random sample
    WHERE "trip_seconds" BETWEEN 0 AND 3600   -- keep 0–60-minute trips
),
quantiled AS (
    SELECT
        "trip_seconds",
        "fare",
        NTILE(6) OVER (ORDER BY "trip_seconds") AS "duration_quantile"
    FROM sampled
)
SELECT
    "duration_quantile",
    ROUND(MIN("trip_seconds") / 60.0) AS "min_trip_minutes",
    ROUND(MAX("trip_seconds") / 60.0) AS "max_trip_minutes",
    COUNT(*)                           AS "total_trips",
    AVG("fare")                        AS "avg_fare"
FROM quantiled
GROUP BY "duration_quantile"
ORDER BY "duration_quantile";