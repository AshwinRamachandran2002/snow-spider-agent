WITH filtered AS (             -- keep only trips 1–50 minutes & needed columns
    SELECT
        ROUND("trip_seconds" / 60.0)::INT  AS duration_min,
        "fare"
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    WHERE "trip_seconds" BETWEEN 60 AND 3000      -- 1-50 minutes
      AND "fare" IS NOT NULL
),
dur_stats AS (                  -- aggregate once per minute value (≤50 rows)
    SELECT
        duration_min,
        COUNT(*)              AS trip_cnt,
        SUM("fare")           AS fare_sum
    FROM filtered
    GROUP BY duration_min
),
cum AS (                        -- cumulative trips to form weighted NTILE
    SELECT
        duration_min,
        trip_cnt,
        fare_sum,
        SUM(trip_cnt) OVER (ORDER BY duration_min)          AS cum_cnt,
        SUM(trip_cnt) OVER ()                               AS total_cnt
    FROM dur_stats
),
bucketed AS (                   -- assign 10 equal-sized quantile groups
    SELECT
        duration_min,
        trip_cnt,
        fare_sum,
        CEIL(cum_cnt * 10.0 / total_cnt)   AS bucket        -- 1-10
    FROM cum
),
agg AS (                        -- final aggregation per bucket
    SELECT
        bucket,
        MIN(duration_min)                          AS min_min,
        MAX(duration_min)                          AS max_min,
        SUM(trip_cnt)                              AS total_trips,
        ROUND(SUM(fare_sum) / SUM(trip_cnt), 2)    AS avg_fare
    FROM bucketed
    GROUP BY bucket
)
SELECT
    LPAD(min_min, 2, '0') || 'm to ' || LPAD(max_min, 2, '0') || 'm'  AS "TIME_RANGE",
    total_trips                                                      AS "TOTAL_TRIPS",
    TO_CHAR(avg_fare, 'FM99999990.00')                               AS "AVERAGE_FARE"
FROM agg
ORDER BY min_min;