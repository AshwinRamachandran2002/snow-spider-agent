-- Top-5 (ZIP, hour) combinations on 1-Jan-2015 ranked by yellow-cab pickups
WITH
/* ── 1.  NYC ZIP-code polygons ─────────────────────────────────────────────── */
nyc_zips AS (
  SELECT
    zip_code,
    zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_code = 'NY'         -- keep only New-York-State ZIPs
),

/* ── 2.  Hour stamps for the analysis day (00-23h) ─────────────────────────── */
hours AS (
  SELECT h AS hour_start
  FROM UNNEST(
        GENERATE_TIMESTAMP_ARRAY('2015-01-01 00:00:00',
                                 '2015-01-01 23:00:00',
                                 INTERVAL 1 HOUR)
       ) AS h
),

/* ── 3.  Full ZIP  ×  hour grid for 1-Jan-2015 (keeps zero-trip rows) ──────── */
jan1_grid AS (
  SELECT z.zip_code, h.hour_start
  FROM nyc_zips AS z
  CROSS JOIN hours AS h
),

/* ── 4.  Hourly pickup counts for the 21-day look-back window ──────────────── */
hourly_trips AS (
  SELECT
    z.zip_code,
    TIMESTAMP_TRUNC(t.pickup_datetime, HOUR) AS hour_start,
    COUNT(*) AS trips
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2015` AS t
  JOIN nyc_zips AS z
    ON ST_CONTAINS(
         z.zip_code_geom,
         ST_GEOGPOINT(t.pickup_longitude, t.pickup_latitude)
       )
  WHERE t.pickup_datetime >= '2014-12-11'          -- 21-day history
    AND t.pickup_datetime <  '2015-01-02'
    AND t.pickup_latitude  IS NOT NULL            -- keep only valid coords
    AND t.pickup_longitude IS NOT NULL
    AND t.pickup_latitude  != 0
    AND t.pickup_longitude != 0
  GROUP BY z.zip_code, hour_start
),

/* ── 5.  Attach the zero-trip grid for 1-Jan-2015 ──────────────────────────── */
jan1_counts AS (
  SELECT
    g.zip_code,
    g.hour_start,
    COALESCE(h.trips, 0) AS trips
  FROM jan1_grid AS g
  LEFT JOIN hourly_trips AS h
    USING (zip_code, hour_start)
),

/* ── 6.  Combine history + filled-in 1-Jan rows and de-dup ─────────────────── */
all_hours AS (
  SELECT * FROM hourly_trips
  UNION ALL
  SELECT * FROM jan1_counts     -- guarantees every (ZIP,hour) on 1-Jan exists
),
dedup AS (                      -- if a row appears twice, keep the highest cnt
  SELECT
    zip_code,
    hour_start,
    MAX(trips) AS trips
  FROM all_hours
  GROUP BY zip_code, hour_start
),

/* ── 7.  Time-lag features & moving-window stats ───────────────────────────── */
metrics AS (
  SELECT
    zip_code,
    hour_start,
    trips,
    LAG(trips,   1)  OVER w AS trips_1h_ago,
    LAG(trips,  24)  OVER w AS trips_24h_ago,
    LAG(trips, 168)  OVER w AS trips_7d_ago,
    LAG(trips, 336)  OVER w AS trips_14d_ago,
    AVG(trips)       OVER w14 AS ma_14d,
    STDDEV(trips)    OVER w14 AS std_14d,
    AVG(trips)       OVER w21 AS ma_21d,
    STDDEV(trips)    OVER w21 AS std_21d
  FROM dedup
  WINDOW
    w   AS (PARTITION BY zip_code ORDER BY hour_start),
    w14 AS (PARTITION BY zip_code ORDER BY hour_start
            ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING),   -- 14 days
    w21 AS (PARTITION BY zip_code ORDER BY hour_start
            ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING)    -- 21 days
)

/* ── 8.  Final report: top-5 ZIP-hours on 1-Jan-2015 ───────────────────────── */
SELECT
  zip_code,
  hour_start,
  trips,
  trips_1h_ago,
  trips_24h_ago,
  trips_7d_ago,
  trips_14d_ago,
  ma_14d,
  std_14d,
  ma_21d,
  std_21d
FROM metrics
WHERE hour_start BETWEEN '2015-01-01 00:00:00' AND '2015-01-01 23:59:59'
ORDER BY trips DESC
LIMIT 5;