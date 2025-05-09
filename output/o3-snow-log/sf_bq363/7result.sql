/* 1)  Aggregate the data to one row per whole-minute duration (1–50 minutes)   */
WITH minutes AS (           
    SELECT
        ROUND("trip_seconds" / 60.0)                        AS rounded_minutes,   -- whole-minute duration
        COUNT(*)                                            AS trip_cnt,          -- # trips with that duration
        SUM("fare")                                         AS total_fare         -- total fare for that duration
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    WHERE "trip_seconds" BETWEEN 60 AND 3000                -- keep 1–50 minute trips
      AND "fare" IS NOT NULL
    GROUP BY ROUND("trip_seconds" / 60.0)
    HAVING rounded_minutes BETWEEN 1 AND 50                 -- keep only 1–50 after rounding
),

/* 2)  Compute cumulative trip counts so we can assign equal-sized buckets      */
cum AS (
    SELECT
        rounded_minutes,
        trip_cnt,
        total_fare,
        SUM(trip_cnt) OVER (ORDER BY rounded_minutes)       AS cume_cnt,   -- running total
        SUM(trip_cnt) OVER ()                               AS total_cnt   -- grand total
    FROM minutes
),

/* 3)  Assign each rounded-minute value to one of ten quantiles                 */
bucketed AS (
    SELECT
        rounded_minutes,
        trip_cnt,
        total_fare,
        LEAST(10, CEIL(10 * cume_cnt / total_cnt))          AS quantile     -- 1-10
    FROM cum
),

/* 4)  Aggregate statistics for every quantile                                  */
agg AS (
    SELECT
        quantile,
        MIN(rounded_minutes)                                AS min_min,
        MAX(rounded_minutes)                                AS max_min,
        SUM(trip_cnt)                                       AS total_trips,
        ROUND(SUM(total_fare) / SUM(trip_cnt), 2)           AS avg_fare
    FROM bucketed
    GROUP BY quantile
)

/* 5)  Format the output                                                         */
SELECT
    LPAD(TO_VARCHAR(min_min), 2, '0') || 'm to ' ||
    LPAD(TO_VARCHAR(max_min), 2, '0') || 'm'                AS time_range,
    total_trips,
    avg_fare
FROM agg
ORDER BY min_min;                                            -- chronological order