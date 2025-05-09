WITH minute_stats AS (            -- collapse to at most 50 rows first
    SELECT
        ROUND("trip_seconds" / 60.0)          AS trip_minutes,
        COUNT(*)                              AS cnt,
        SUM("fare")                           AS fare_sum
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    WHERE "trip_seconds" BETWEEN 60 AND 3000          -- 1-50 minutes (pre-rounding)
    GROUP BY trip_minutes
    HAVING trip_minutes BETWEEN 1 AND 50
),
total_cnt AS (                                  -- total trips in the 1-50-minute window
    SELECT SUM(cnt) AS total_trips
    FROM minute_stats
),
ordered AS (                                   -- cumulative counts for quantile assignment
    SELECT
        ms.trip_minutes,
        ms.cnt,
        ms.fare_sum,
        SUM(ms.cnt) OVER (ORDER BY ms.trip_minutes) AS cum_cnt,
        tc.total_trips
    FROM minute_stats ms
    CROSS JOIN total_cnt tc
),
bucketed AS (                                  -- assign each minute value to a quantile
    SELECT
        CEIL(10 * cum_cnt / total_trips)       AS quantile,
        trip_minutes,
        cnt,
        fare_sum
    FROM ordered
),
agg AS (                                       -- aggregate metrics within each quantile
    SELECT
        quantile,
        MIN(trip_minutes)                      AS min_min,
        MAX(trip_minutes)                      AS max_min,
        SUM(cnt)                               AS total_trips,
        ROUND(SUM(fare_sum) / SUM(cnt), 2)     AS average_fare
    FROM bucketed
    GROUP BY quantile
)
SELECT
    LPAD(min_min::VARCHAR, 2, '0') || 'm to ' ||
    LPAD(max_min::VARCHAR, 2, '0') || 'm'      AS "time_range",
    total_trips,
    average_fare
FROM agg
ORDER BY min_min;