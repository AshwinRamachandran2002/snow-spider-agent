WITH durations AS (                      -- 1) collapse data to 50 rows (1-50 minutes)
    SELECT
        ROUND("trip_seconds" / 60.0)::INT  AS duration_minutes,   -- 0-dp rounding
        COUNT(*)                           AS trip_count,
        SUM("fare")                        AS total_fare
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    WHERE "trip_seconds" BETWEEN 60 AND 3000        -- 1–50 minutes only
      AND "fare" IS NOT NULL
    GROUP BY duration_minutes
    HAVING duration_minutes BETWEEN 1 AND 50
),
tot AS (                                  -- 2) total trips across the 50 durations
    SELECT SUM(trip_count) AS total_trips
    FROM durations
),
cum AS (                                  -- 3) cumulative count to derive quantiles
    SELECT
        d.*,
        SUM(trip_count) OVER (ORDER BY duration_minutes)     AS cum_trips,
        t.total_trips
    FROM durations d
    CROSS JOIN tot t
),
quantiled AS (                            -- 4) assign each duration to a quantile
    SELECT
        duration_minutes,
        trip_count,
        total_fare,
        CEIL(cum_trips * 10.0 / total_trips) AS quantile     -- 10 equal groups
    FROM cum
),
agg AS (                                  -- 5) aggregate per quantile
    SELECT
        quantile,
        MIN(duration_minutes)              AS min_dur,
        MAX(duration_minutes)              AS max_dur,
        SUM(trip_count)                    AS total_trips,
        ROUND(SUM(total_fare) / SUM(trip_count), 2) AS average_fare
    FROM quantiled
    GROUP BY quantile
)
SELECT                                     -- 6) final formatted output
    LPAD(min_dur::VARCHAR, 2, '0') || 'm to ' ||
    LPAD(max_dur::VARCHAR, 2, '0') || 'm'          AS time_range,
    total_trips,
    average_fare
FROM agg
ORDER BY min_dur;