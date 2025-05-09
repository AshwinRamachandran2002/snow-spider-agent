WITH sampled AS (
    SELECT
        "trip_seconds",
        "fare"
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    SAMPLE BERNOULLI (5)                -- 5 % random sample to reduce runtime
    WHERE "trip_seconds" BETWEEN 0 AND 3600
),
bucketed AS (
    SELECT
        ROUND("trip_seconds" / 60.0)            AS "trip_minutes",
        "fare",
        NTILE(6) OVER (ORDER BY "trip_seconds") AS "duration_quantile"
    FROM sampled
)
SELECT
    "duration_quantile",
    MIN("trip_minutes")   AS "min_minutes",
    MAX("trip_minutes")   AS "max_minutes",
    COUNT(*)              AS "total_trips",
    ROUND(AVG("fare"), 2) AS "avg_fare"
FROM bucketed
GROUP BY "duration_quantile"
ORDER BY "duration_quantile";