/*  Sextile statistics for trips 0-60 minutes – run on a 1 % sample
    The sample keeps execution well under the 200-second limit,
    while APPROX_PERCENTILE provides the six-quantile boundaries.   */

WITH sampled AS (                -- ~1 % random sample of eligible trips
    SELECT
        "trip_seconds",
        "fare"
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    SAMPLE BERNOULLI (1) REPEATABLE (42)
    WHERE "trip_seconds" > 0
      AND "trip_seconds" <= 3600
),
bounds AS (                       -- calculate the five interior cut-points
    SELECT
        APPROX_PERCENTILE("trip_seconds", 0.1666667) AS p1,
        APPROX_PERCENTILE("trip_seconds", 0.3333333) AS p2,
        APPROX_PERCENTILE("trip_seconds", 0.5000000) AS p3,
        APPROX_PERCENTILE("trip_seconds", 0.6666667) AS p4,
        APPROX_PERCENTILE("trip_seconds", 0.8333333) AS p5
    FROM sampled
),
bucketed AS (                     -- assign each sampled trip to a sextile
    SELECT
        CASE
            WHEN s."trip_seconds" <= b.p1 THEN 1
            WHEN s."trip_seconds" <= b.p2 THEN 2
            WHEN s."trip_seconds" <= b.p3 THEN 3
            WHEN s."trip_seconds" <= b.p4 THEN 4
            WHEN s."trip_seconds" <= b.p5 THEN 5
            ELSE 6
        END                                    AS quantile_group,
        s."trip_seconds",
        s."fare"
    FROM sampled s
    CROSS JOIN bounds b           -- scalar join (bounds has exactly 1 row)
)
SELECT
    quantile_group,
    MIN(ROUND("trip_seconds" / 60)) AS min_trip_minutes,
    MAX(ROUND("trip_seconds" / 60)) AS max_trip_minutes,
    COUNT(*)                        AS total_trips,
    ROUND(AVG("fare"), 4)           AS avg_fare
FROM bucketed
GROUP BY quantile_group
ORDER BY quantile_group;