/*  NYC Yellow-taxi – 1 Jan 2015
    Hourly trip counts per ZIP (with zero-fill) and lag / moving-window metrics   */

WITH
-- ---------------------------------------------------------------------------
-- 1) 24 hourly instants covering 2015-01-01 UTC
hours AS (
  SELECT TIMESTAMP '2015-01-01 00:00:00+00' + INTERVAL h HOUR AS hr
  FROM UNNEST(GENERATE_ARRAY(0,23)) AS h
),

-- ---------------------------------------------------------------------------
-- 2) Yellow-cab pickups on 1-Jan-2015 with plausible NYC coordinates
raw_trips AS (
  SELECT
    pickup_datetime,
    pickup_longitude   AS lon,
    pickup_latitude    AS lat
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2015`
  WHERE DATE(pickup_datetime) = '2015-01-01'
    AND pickup_longitude BETWEEN -74.3 AND -73.7   -- crude NYC bounding box
    AND pickup_latitude  BETWEEN  40.4  AND  41.0
),

-- ---------------------------------------------------------------------------
-- 3) Attach ZIP code by spatial containment of the pickup point
trips_zip AS (
  SELECT
    z.zip_code,
    TIMESTAMP_TRUNC(t.pickup_datetime, HOUR) AS hr
  FROM raw_trips AS t
  JOIN `bigquery-public-data.geo_us_boundaries.zip_codes` AS z
    ON ST_CONTAINS(z.zip_code_geom, ST_GEOGPOINT(t.lon, t.lat))
  WHERE z.state_code = 'NY'
),

-- ---------------------------------------------------------------------------
-- 4) ZIPs that actually receive at least one pickup that day
zip_list AS (SELECT DISTINCT zip_code FROM trips_zip),

-- ---------------------------------------------------------------------------
-- 5) Skeleton grid  (every ZIP × every hour) – guarantees zero-filled series
grid AS (
  SELECT z.zip_code, h.hr
  FROM zip_list z
  CROSS JOIN hours h
),

-- ---------------------------------------------------------------------------
-- 6) Raw trip counts per (zip, hour)
hourly AS (
  SELECT
    zip_code,
    hr,
    COUNT(*) AS trips
  FROM trips_zip
  GROUP BY zip_code, hr
),

-- ---------------------------------------------------------------------------
-- 7) Zero-fill missing (zip,hr) combinations
series AS (
  SELECT
    g.zip_code,
    g.hr,
    COALESCE(h.trips, 0) AS trips
  FROM grid AS g
  LEFT JOIN hourly AS h
  USING (zip_code, hr)
),

-- ---------------------------------------------------------------------------
-- 8) Lag values and moving-window statistics
metrics AS (
  SELECT
    zip_code,
    hr,
    trips,

    -- Lags
    LAG(trips, 1)   OVER w AS trips_1h_ago,
    LAG(trips, 24)  OVER w AS trips_24h_ago,
    LAG(trips, 168) OVER w AS trips_7d_ago,
    LAG(trips, 336) OVER w AS trips_14d_ago,

    -- Moving averages / std-deviations (exclude current hour)
    AVG(trips)        OVER w14 AS avg_14d,
    STDDEV_POP(trips) OVER w14 AS sd_14d,
    AVG(trips)        OVER w21 AS avg_21d,
    STDDEV_POP(trips) OVER w21 AS sd_21d
  FROM series
  WINDOW
    w   AS (PARTITION BY zip_code ORDER BY hr),
    w14 AS (PARTITION BY zip_code ORDER BY hr ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING),
    w21 AS (PARTITION BY zip_code ORDER BY hr ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING)
)

-- ---------------------------------------------------------------------------
SELECT *
FROM metrics
ORDER BY trips DESC        -- top 5 (zip,hr) combinations by current trips
LIMIT 5;