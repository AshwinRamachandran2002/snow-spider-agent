/* -------------------------------------------------------------
   FAST APPROXIMATE VERSION (5 % sample to avoid time-out)
   ------------------------------------------------------------- */
WITH sampled AS (                               -- 5 % of trips, 0-60 min only
    SELECT
        "trip_seconds",
        "fare"
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
         SAMPLE BERNOULLI (5)                  -- sample clause must come right after table
    WHERE "trip_seconds" BETWEEN 0 AND 3600
),                                             
bucketed AS (                                   -- slice the sample into 6 equal-count buckets
    SELECT
        "trip_seconds",
        "fare",
        NTILE(6) OVER (ORDER BY "trip_seconds") AS "quantile_group"
    FROM sampled
)
SELECT
    "quantile_group",
    ROUND( MIN("trip_seconds") / 60.0 ) AS "min_minutes",
    ROUND( MAX("trip_seconds") / 60.0 ) AS "max_minutes",
    ROUND( COUNT(*) * 20 )              AS "num_trips",   -- scale up (1 / 0.05)
    ROUND( AVG("fare"), 2 )             AS "avg_fare"
FROM bucketed
GROUP BY "quantile_group"
ORDER BY "quantile_group";