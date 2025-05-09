WITH sampled AS (    -- random 0.05 % sample of trips lasting 0-60 minutes
    SELECT "trip_seconds",
           "fare"
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
         TABLESAMPLE BERNOULLI (0.05)
    WHERE "trip_seconds" BETWEEN 0 AND 3600
),
bounds AS (          -- approximate 1/6-quantile breakpoints
    SELECT
        APPROX_PERCENTILE("trip_seconds", 0.166667) AS p1,
        APPROX_PERCENTILE("trip_seconds", 0.333333) AS p2,
        APPROX_PERCENTILE("trip_seconds", 0.500000) AS p3,
        APPROX_PERCENTILE("trip_seconds", 0.666667) AS p4,
        APPROX_PERCENTILE("trip_seconds", 0.833333) AS p5
    FROM sampled
),
bucketed AS (        -- assign each sampled trip to a bucket
    SELECT
        CASE
            WHEN s."trip_seconds" <= b.p1 THEN 1
            WHEN s."trip_seconds" <= b.p2 THEN 2
            WHEN s."trip_seconds" <= b.p3 THEN 3
            WHEN s."trip_seconds" <= b.p4 THEN 4
            WHEN s."trip_seconds" <= b.p5 THEN 5
            ELSE 6
        END                          AS "duration_group",
        s."trip_seconds",
        s."fare"
    FROM sampled s
    CROSS JOIN bounds b
)
SELECT                -- final metrics per duration group
    "duration_group",
    ROUND(MIN("trip_seconds") / 60.0) AS "min_minutes",
    ROUND(MAX("trip_seconds") / 60.0) AS "max_minutes",
    COUNT(*)                          AS "total_trips",
    ROUND(AVG("fare"), 2)             AS "average_fare"
FROM bucketed
GROUP BY "duration_group"
ORDER BY "duration_group";