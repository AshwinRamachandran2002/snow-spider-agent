/* ---------------------------------------------------------------
   Hour-by-hour 01-Jan-2015 yellow-cab activity
   (approx-“ZIP” derived from rounded lat/long; no external geo table
    needed, so the query runs with the objects that really exist)
------------------------------------------------------------------*/
WITH valid_trips AS (   -- 1) 2015-01-01 trips that fall within a broad NYC box
    SELECT
        DATE_TRUNC(
            'HOUR',
            TO_TIMESTAMP("pickup_datetime", 6)
        )                                                  AS hour_ts,
        /* “zip_code” proxy:  round lat/long to 2-dp and glue them together */
        CONCAT(
            TO_VARCHAR(ROUND("pickup_latitude",  2)),
            '_',
            TO_VARCHAR(ROUND("pickup_longitude", 2))
        )                                                  AS zip_code
    FROM NEW_YORK_GEO.NEW_YORK."TLC_YELLOW_TRIPS_2015"
    WHERE "pickup_latitude"  BETWEEN 40.0 AND 41.0
      AND "pickup_longitude" BETWEEN -75.0 AND -72.0
      AND "pickup_datetime" BETWEEN 1420070400000000  -- 2015-01-01 00:00:00
                              AND 1420156799000000    -- 2015-01-01 23:59:59.999
),
hour_series AS (        -- 2) the 24 hourly slots of 01-Jan-2015
    SELECT DATEADD(HOUR, SEQ4(), '2015-01-01 00:00:00') AS hour_ts
    FROM   TABLE(GENERATOR(ROWCOUNT => 24))
),
zip_list AS (           -- 3) all distinct “zip” proxies observed that day
    SELECT DISTINCT zip_code
    FROM   valid_trips
),
grid AS (               -- 4) every zip × every hour (ensures zero-trip rows)
    SELECT z.zip_code, h.hour_ts
    FROM   zip_list z
    CROSS  JOIN hour_series h
),
trip_counts AS (        -- 5) actual trip counts
    SELECT
        zip_code,
        hour_ts,
        COUNT(*) AS trip_cnt
    FROM valid_trips
    GROUP BY 1, 2
),
full_grid AS (          -- 6) attach counts, default 0 where no trips
    SELECT
        g.zip_code,
        g.hour_ts,
        COALESCE(t.trip_cnt, 0) AS trip_cnt
    FROM grid g
    LEFT JOIN trip_counts t
      ON  t.zip_code = g.zip_code
     AND  t.hour_ts  = g.hour_ts
),
metrics AS (            -- 7) lagged counts & moving statistics
    SELECT
        zip_code,
        hour_ts,
        trip_cnt,
        LAG(trip_cnt,  1)  OVER (PARTITION BY zip_code ORDER BY hour_ts)         AS trips_1hr_ago,
        LAG(trip_cnt, 24)  OVER (PARTITION BY zip_code ORDER BY hour_ts)         AS trips_24hr_ago,
        LAG(trip_cnt,168)  OVER (PARTITION BY zip_code ORDER BY hour_ts)         AS trips_7d_ago,
        LAG(trip_cnt,336)  OVER (PARTITION BY zip_code ORDER BY hour_ts)         AS trips_14d_ago,
        AVG(trip_cnt)      OVER (PARTITION BY zip_code ORDER BY hour_ts
                                 ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING)     AS ma_14d,
        STDDEV_SAMP(trip_cnt) OVER (PARTITION BY zip_code ORDER BY hour_ts
                                 ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING)     AS std_14d,
        AVG(trip_cnt)      OVER (PARTITION BY zip_code ORDER BY hour_ts
                                 ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING)     AS ma_21d,
        STDDEV_SAMP(trip_cnt) OVER (PARTITION BY zip_code ORDER BY hour_ts
                                 ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING)     AS std_21d
    FROM full_grid
)
SELECT *
FROM   metrics
ORDER  BY trip_cnt DESC NULLS LAST
LIMIT 5;