WITH duration_stats AS (          -- 1. aggregate to at most 50 rows (1–50 minutes)
    SELECT
        ROUND("trip_seconds" / 60.0)                    AS rounded_minutes,
        COUNT(*)                                        AS trips,
        SUM("fare")                                     AS sum_fare
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    WHERE "trip_seconds" IS NOT NULL
      AND "fare" IS NOT NULL
      AND ROUND("trip_seconds" / 60.0) BETWEEN 1 AND 50
    GROUP BY rounded_minutes
),
cum AS (                       -- 2. cumulative counts to determine quantiles
    SELECT
        rounded_minutes,
        trips,
        sum_fare,
        SUM(trips) OVER (ORDER BY rounded_minutes)          AS cum_trips,
        SUM(trips) OVER ()                                   AS total_trips
    FROM duration_stats
),
buckets AS (                   -- 3. assign each minute-bucket to one of 10 quantiles
    SELECT
        rounded_minutes,
        trips,
        sum_fare,
        CEIL(cum_trips / NULLIF(total_trips, 0) * 10)        AS decile
    FROM cum
)
SELECT                                                      -- 4. final answer
    LPAD(TO_VARCHAR(MIN(rounded_minutes)), 2, '0') || 'm to ' ||
    LPAD(TO_VARCHAR(MAX(rounded_minutes)), 2, '0') || 'm'   AS "time_range",
    SUM(trips)                                              AS "total_trips",
    TO_DECIMAL(SUM(sum_fare) / NULLIF(SUM(trips), 0), 10, 2) AS "average_fare"
FROM buckets
GROUP BY decile
ORDER BY MIN(rounded_minutes);