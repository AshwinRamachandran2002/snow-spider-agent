WITH filtered AS (
    SELECT
        ROUND("trip_seconds" / 60.0)    AS duration_minutes,   -- rounded trip time (minutes)
        "fare"
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    WHERE "trip_seconds" IS NOT NULL
      AND ROUND("trip_seconds" / 60.0) BETWEEN 1 AND 50         -- keep trips 1-50 min
),
quantiled AS (
    SELECT
        duration_minutes,
        "fare",
        NTILE(10) OVER (ORDER BY duration_minutes) AS quantile  -- 10 equal-sized groups
    FROM filtered
),
aggregated AS (
    SELECT
        quantile,
        MIN(duration_minutes)                       AS min_minute,
        MAX(duration_minutes)                       AS max_minute,
        COUNT(*)                                    AS total_trips,
        AVG("fare")                                 AS avg_fare
    FROM quantiled
    GROUP BY quantile
)
SELECT
    LPAD(min_minute::STRING, 2, '0') || 'm to ' ||
    LPAD(max_minute::STRING, 2, '0') || 'm'        AS time_range,
    total_trips,
    ROUND(avg_fare, 2)                             AS average_fare
FROM aggregated
ORDER BY min_minute;