/* Hour‑by‑hour NYC yellow‑cab activity for 1‑Jan‑2015 */
WITH
/* 1 ── trips that have syntactically valid coordinates */
trips_valid AS (
  SELECT
    pickup_datetime,
    pickup_longitude,
    pickup_latitude
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2015`
  WHERE pickup_longitude IS NOT NULL
    AND pickup_latitude  IS NOT NULL
    AND pickup_longitude BETWEEN -180 AND 180
    AND pickup_latitude  BETWEEN  -90 AND  90
    AND pickup_longitude <> 0
    AND pickup_latitude  <> 0
),

/* 2 ── attach ZIP code + truncate pick‑up time to the HOUR (TIMESTAMP) */
trips_with_zip AS (
  SELECT
    z.zip_code,
    TIMESTAMP_TRUNC(t.pickup_datetime, HOUR) AS hr        -- TIMESTAMP
  FROM trips_valid AS t
  JOIN `bigquery-public-data.geo_us_boundaries.zip_codes` AS z
  ON  ST_CONTAINS(
        z.zip_code_geom,
        ST_GEOGPOINT(t.pickup_longitude, t.pickup_latitude)
      )
  WHERE z.state_code = 'NY'
),

/* 3 ── hourly trip counts per ZIP for all of 2015 */
hourly_trips AS (
  SELECT
    zip_code,
    hr,
    COUNT(*) AS trip_cnt
  FROM trips_with_zip
  GROUP BY zip_code, hr
),

/* 4 ── lagged counts & moving stats (exclude current hour) */
metrics AS (
  SELECT
    zip_code,
    hr,
    trip_cnt,
    LAG(trip_cnt,   1)  OVER (PARTITION BY zip_code ORDER BY hr) AS cnt_1hr_ago,
    LAG(trip_cnt,  24)  OVER (PARTITION BY zip_code ORDER BY hr) AS cnt_24hr_ago,
    LAG(trip_cnt, 168)  OVER (PARTITION BY zip_code ORDER BY hr) AS cnt_168hr_ago,
    LAG(trip_cnt, 336)  OVER (PARTITION BY zip_code ORDER BY hr) AS cnt_336hr_ago,
    AVG(trip_cnt)       OVER (PARTITION BY zip_code ORDER BY hr
                              ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS ma_14day,
    STDDEV_POP(trip_cnt)OVER (PARTITION BY zip_code ORDER BY hr
                              ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS std_14day,
    AVG(trip_cnt)       OVER (PARTITION BY zip_code ORDER BY hr
                              ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS ma_21day,
    STDDEV_POP(trip_cnt)OVER (PARTITION BY zip_code ORDER BY hr
                              ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS std_21day
  FROM hourly_trips
),

/* 5 ── every NY ZIP × every hour on 1‑Jan‑2015 */
jan1_hours AS (
  SELECT hr
  FROM UNNEST(
        GENERATE_TIMESTAMP_ARRAY('2015-01-01 00:00:00',
                                 '2015-01-01 23:00:00',
                                 INTERVAL 1 HOUR)) AS hr
),
ny_zips AS (
  SELECT DISTINCT zip_code
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_code = 'NY'
),
grid AS (
  SELECT z.zip_code, h.hr
  FROM ny_zips z
  CROSS JOIN jan1_hours h
)

/* 6 ── final join (zero‑fill) & top‑5 by trip volume */
SELECT
  g.zip_code,
  g.hr,
  IFNULL(m.trip_cnt, 0)      AS trip_cnt,
  m.cnt_1hr_ago,
  m.cnt_24hr_ago,
  m.cnt_168hr_ago,
  m.cnt_336hr_ago,
  m.ma_14day,
  m.std_14day,
  m.ma_21day,
  m.std_21day
FROM grid g
LEFT JOIN metrics m
  ON  g.zip_code = m.zip_code
  AND g.hr       = m.hr
ORDER BY trip_cnt DESC, g.zip_code, g.hr
LIMIT 5;