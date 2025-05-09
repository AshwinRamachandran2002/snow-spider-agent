WITH base AS (  -- trips that last 1-50 minutes
    SELECT
        ROUND("trip_seconds" / 60.0)::INT AS duration_min,
        "fare"
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    WHERE "trip_seconds" BETWEEN 60 AND 3000        -- 1–50 minutes
),
agg AS (         -- compress to one row per minute
    SELECT
        duration_min,
        COUNT(*)        AS trips,
        SUM("fare")     AS total_fare
    FROM base
    GROUP BY duration_min
),
ordered AS (     -- running and total trip counts
    SELECT
        duration_min,
        trips,
        total_fare,
        SUM(trips) OVER (ORDER BY duration_min) AS cum_trips,
        SUM(trips) OVER ()                      AS all_trips
    FROM agg
),
assigned AS (    -- assign quantile based on cumulative trips
    SELECT
        duration_min,
        trips,
        total_fare,
        LEAST(CEIL(10 * cum_trips / all_trips), 10) AS quantile
    FROM ordered
),
summary AS (     -- aggregate statistics per quantile
    SELECT
        quantile,
        MIN(duration_min)                 AS min_dur,
        MAX(duration_min)                 AS max_dur,
        SUM(trips)                        AS total_trips,
        ROUND(SUM(total_fare) / SUM(trips), 2) AS avg_fare
    FROM assigned
    GROUP BY quantile
)
SELECT
    LPAD(min_dur::STRING, 2, '0') || 'm to ' ||
    LPAD(max_dur::STRING, 2, '0') || 'm'  AS "time_range",
    total_trips                           AS "total_trips",
    TO_DECIMAL(avg_fare, 10, 2)           AS "average_fare"
FROM summary
ORDER BY min_dur;