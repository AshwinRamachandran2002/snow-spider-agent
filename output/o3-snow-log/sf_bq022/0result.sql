WITH sampled AS (            -- ≈0.2 % random sample to keep the query fast
    SELECT
        "trip_seconds",
        "fare"
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    SAMPLE BERNOULLI (0.2)                     -- 0.2 % of the rows
    WHERE "trip_seconds" BETWEEN 0 AND 3600    -- 0- to 60-minute trips
),
bucketed AS (
    SELECT
        NTILE(6) OVER (ORDER BY "trip_seconds") AS "quantile_group",
        "trip_seconds",
        "fare"
    FROM sampled
)
SELECT
    "quantile_group",
    ROUND(MIN("trip_seconds") / 60.0) AS "min_trip_minutes",
    ROUND(MAX("trip_seconds") / 60.0) AS "max_trip_minutes",
    COUNT(*)                          AS "total_trips",
    ROUND(AVG("fare"), 2)             AS "avg_fare"
FROM bucketed
GROUP BY "quantile_group"
ORDER BY "quantile_group";