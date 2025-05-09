-- Top-5 NYC ZIP-code / hour buckets on 1-Jan-2015
-- together with lagged counts and rolling statistics
WITH
-- ─────────────── parameters ───────────────
params AS (
  SELECT
    TIMESTAMP('2014-12-11 00:00:00+00') AS t_start ,   -- 21-day look-back
    TIMESTAMP('2015-01-01 23:00:00+00') AS t_end
),

-- ─────────────── dense hour vector ───────────────
hours AS (
  SELECT h AS hr
  FROM params,
  UNNEST(GENERATE_TIMESTAMP_ARRAY(t_start, t_end, INTERVAL 1 HOUR)) AS h
),

-- ─────────────── all NYS ZIP polygons ───────────────
zips AS (
  SELECT
    zip_code,
    zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_code = 'NY'
),

-- ─────────────── full ZIP × hour grid ───────────────
grid AS (
  SELECT
    z.zip_code,
    h.hr
  FROM zips AS z
  CROSS JOIN hours AS h
),

-- ─────────────── hourly pickup counts ───────────────
facts AS (
  SELECT
    z.zip_code,
    TIMESTAMP_TRUNC(t.pickup_datetime, HOUR) AS hr,
    COUNT(*) AS trips
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2015` AS t
  JOIN zips AS z
    ON ST_CONTAINS(z.zip_code_geom,
                   ST_GEOGPOINT(t.pickup_longitude, t.pickup_latitude))
  WHERE t.pickup_datetime BETWEEN (SELECT t_start FROM params)
                              AND (SELECT t_end   FROM params)
    AND t.pickup_longitude IS NOT NULL  AND t.pickup_latitude IS NOT NULL
    AND t.pickup_longitude != 0         AND t.pickup_latitude  != 0
  GROUP BY z.zip_code, hr
),

-- ─────────────── grid left-joined to facts ───────────────
dense AS (
  SELECT
    g.zip_code,
    g.hr,
    COALESCE(f.trips, 0) AS trips
  FROM grid AS g
  LEFT JOIN facts AS f
  USING (zip_code, hr)
),

-- ─────────────── lagged counts & moving stats ───────────────
metrics AS (
  SELECT
    zip_code,
    hr,
    trips,
    LAG(trips,   1) OVER w AS trips_1hr_ago,
    LAG(trips,  24) OVER w AS trips_24hr_ago,
    LAG(trips, 168) OVER w AS trips_7d_ago,
    LAG(trips, 336) OVER w AS trips_14d_ago,

    AVG(trips)     OVER (w ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS avg_14d,
    STDDEV_POP(trips) OVER (w ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS stddev_14d,

    AVG(trips)     OVER (w ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS avg_21d,
    STDDEV_POP(trips) OVER (w ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS stddev_21d
  FROM dense
  WINDOW w AS (PARTITION BY zip_code ORDER BY hr)
)

-- ─────────────── final output ───────────────
SELECT
  zip_code,
  hr,
  trips,
  trips_1hr_ago,
  trips_24hr_ago,
  trips_7d_ago,
  trips_14d_ago,
  avg_14d,
  stddev_14d,
  avg_21d,
  stddev_21d
FROM metrics
WHERE DATE(hr) = '2015-01-01'
ORDER BY trips DESC
LIMIT 5;