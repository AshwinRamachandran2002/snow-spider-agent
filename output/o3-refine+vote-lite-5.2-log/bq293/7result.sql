-- NYC Yellow‑cab trips on 1‑Jan‑2015 with time–series metrics by ZIP code & hour
WITH
-----------------------------------------------------------------------
-- 1)  Raw trips we care about (+ 21‑day history for lag/MA windows)
-----------------------------------------------------------------------
raw_trips AS (
  SELECT
    pickup_datetime,
    ST_GEOGPOINT(pickup_longitude, pickup_latitude) AS geom
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2015`
  WHERE
    pickup_longitude IS NOT NULL
    AND pickup_latitude  IS NOT NULL
    AND pickup_longitude != 0
    AND pickup_latitude  != 0
    AND DATE(pickup_datetime)
        BETWEEN DATE_SUB(DATE '2015-01-01', INTERVAL 21 DAY)    -- 21‑day look‑back
        AND     DATE '2015-01-01'                               -- analysis day
),

-----------------------------------------------------------------------
-- 2)  Attach NY (five‑borough) ZIP code to each trip using point‑in‑polygon
-----------------------------------------------------------------------
trips_with_zip AS (
  SELECT
    z.zip_code,
    TIMESTAMP_TRUNC(t.pickup_datetime, HOUR) AS pickup_hour
  FROM raw_trips             AS t
  JOIN `bigquery-public-data.geo_us_boundaries.zip_codes` AS z
    ON z.state_code = 'NY'  -- restrict to NYS ZIPs
   AND ST_CONTAINS(z.zip_code_geom, t.geom)
),

-----------------------------------------------------------------------
-- 3)  Actual trip counts per ZIP & hour
-----------------------------------------------------------------------
hourly_counts AS (
  SELECT
    zip_code,
    pickup_hour,
    COUNT(*) AS trips
  FROM trips_with_zip
  GROUP BY zip_code, pickup_hour
),

-----------------------------------------------------------------------
-- 4)  Build the “complete grid” of every NY ZIP crossed with every hour
--     from 11‑Dec‑2014 through 1‑Jan‑2015 (22 days = 528 hours)
-----------------------------------------------------------------------
all_zips  AS (                -- all NY ZIP codes (five boroughs & beyond)
  SELECT DISTINCT zip_code
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_code = 'NY'
),
all_hours AS (
  SELECT h AS pickup_hour
  FROM UNNEST(
        GENERATE_TIMESTAMP_ARRAY(
          TIMESTAMP '2014-12-11 00:00:00',
          TIMESTAMP '2015-01-01 23:00:00',
          INTERVAL 1 HOUR )) AS h
),
zip_hour_grid AS (
  SELECT
    z.zip_code,
    h.pickup_hour
  FROM all_zips z
  CROSS JOIN all_hours h
),

-----------------------------------------------------------------------
-- 5)  Merge real counts (NULL→0) so every ZIP/hour now exists
-----------------------------------------------------------------------
zip_hour_counts AS (
  SELECT
    g.zip_code,
    g.pickup_hour,
    IFNULL(c.trips, 0) AS trips
  FROM zip_hour_grid  AS g
  LEFT JOIN hourly_counts AS c
    ON  c.zip_code     = g.zip_code
    AND c.pickup_hour  = g.pickup_hour
),

-----------------------------------------------------------------------
-- 6)  Calculate lags and moving‑window statistics (exclude current row)
-----------------------------------------------------------------------
metrics AS (
  SELECT
    zip_code,
    pickup_hour,
    trips,

    -- simple lags
    IFNULL(LAG(trips,   1) OVER w, 0) AS trips_1h_ago,
    IFNULL(LAG(trips,  24) OVER w, 0) AS trips_24h_ago,
    IFNULL(LAG(trips, 168) OVER w, 0) AS trips_168h_ago,
    IFNULL(LAG(trips, 336) OVER w, 0) AS trips_336h_ago,

    -- 14‑day (336‑hour) moving statistics *excluding* current hour
    AVG(trips)         OVER w_14 AS avg_14d,
    STDDEV_SAMP(trips) OVER w_14 AS stddev_14d,

    -- 21‑day (504‑hour) moving statistics *excluding* current hour
    AVG(trips)         OVER w_21 AS avg_21d,
    STDDEV_SAMP(trips) OVER w_21 AS stddev_21d

  FROM zip_hour_counts

  WINDOW
    w      AS (PARTITION BY zip_code ORDER BY pickup_hour),
    w_14   AS (PARTITION BY zip_code ORDER BY pickup_hour
               ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING),
    w_21   AS (PARTITION BY zip_code ORDER BY pickup_hour
               ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING)
)

-----------------------------------------------------------------------
-- 7)  Return 1‑Jan‑2015 results, top‑5 ZIP/hour combos by trip count
-----------------------------------------------------------------------
SELECT
  zip_code,
  pickup_hour,
  trips,
  trips_1h_ago,
  trips_24h_ago,
  trips_168h_ago,
  trips_336h_ago,
  avg_14d,
  stddev_14d,
  avg_21d,
  stddev_21d
FROM metrics
WHERE DATE(pickup_hour) = '2015-01-01'
ORDER BY trips DESC, zip_code, pickup_hour
LIMIT 5;