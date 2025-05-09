/*  -----------------------------------------------------------------------
    Ten-quantile summary of taxi-trip fares by rounded trip duration
    (1-50 minutes), using a light-weight two-stage aggregation so that
    only 50 duration buckets are sorted instead of all individual trips.
    -------------------------------------------------------------------- */
WITH duration_stats AS (           -- one row per rounded minute (1-50)
    SELECT
        ROUND("trip_seconds" / 60.0)::INT     AS duration_min,
        COUNT(*)                              AS trips,
        SUM("fare")                           AS total_fare
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    WHERE "trip_seconds" IS NOT NULL
      AND "fare"        IS NOT NULL
      AND "trip_seconds" BETWEEN 60 AND 3000  -- 1-50 mins
    GROUP BY duration_min
    HAVING duration_min BETWEEN 1 AND 50
),
tot AS (                          -- total trips across all 1-50-min rows
    SELECT SUM(trips) AS total_trips
    FROM duration_stats
),
cum AS (                          -- cumulative trips to build deciles
    SELECT
        d.duration_min,
        d.trips,
        d.total_fare,
        SUM(d.trips) OVER (ORDER BY d.duration_min)     AS cum_trips,
        t.total_trips
    FROM duration_stats d
    CROSS JOIN tot t
),
deciles AS (                      -- assign 10 equal-sized quantile groups
    SELECT
        duration_min,
        trips,
        total_fare,
        LEAST(CEIL(cum_trips * 10.0 / total_trips), 10) AS decile
    FROM cum
),
aggregated AS (                   -- aggregate stats inside each decile
    SELECT
        decile,
        MIN(duration_min)                    AS min_dur,
        MAX(duration_min)                    AS max_dur,
        SUM(trips)                           AS total_trips,
        ROUND(SUM(total_fare) / SUM(trips), 2) AS avg_fare
    FROM deciles
    GROUP BY decile
)
SELECT
    LPAD(min_dur::STRING, 2, '0') || 'm to ' ||
    LPAD(max_dur::STRING, 2, '0') || 'm'     AS time_range,
    total_trips,
    avg_fare
FROM aggregated
ORDER BY min_dur;