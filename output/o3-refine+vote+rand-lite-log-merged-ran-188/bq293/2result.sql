-- Top-5 NYC zip-code × hour groups on 1-Jan-2015 with lagged counts,
-- 14-day / 21-day moving averages and standard deviations
WITH nyc_zips AS (
  -- All New York State ZIP-code polygons
  SELECT
    zip_code,
    zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_code = 'NY'
),
raw_trips AS (
  -- 21-day history of yellow-cab pickups with valid coordinates
  SELECT
    TIMESTAMP_TRUNC(pickup_datetime, HOUR) AS hr_ts,
    z.zip_code
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2015` AS t
  JOIN nyc_zips AS z
    ON ST_CONTAINS(z.zip_code_geom,
                   ST_GEOGPOINT(t.pickup_longitude, t.pickup_latitude))
  WHERE pickup_datetime BETWEEN TIMESTAMP('2014-12-11')
                            AND TIMESTAMP('2015-01-02')         -- 21-day window
    AND t.pickup_longitude IS NOT NULL
    AND t.pickup_latitude  IS NOT NULL
    AND t.pickup_longitude <> 0
    AND t.pickup_latitude  <> 0
),
hour_counts AS (
  -- Trips per ZIP and hour
  SELECT
    hr_ts,
    zip_code,
    COUNT(*) AS trips
  FROM raw_trips
  GROUP BY hr_ts, zip_code
),
grid AS (
  -- Complete hour-by-hour grid (includes zeros)
  SELECT
    z.zip_code,
    h AS hr_ts
  FROM nyc_zips AS z
  CROSS JOIN UNNEST(
      GENERATE_TIMESTAMP_ARRAY('2014-12-11 00:00:00+00',
                               '2015-01-01 23:00:00+00',
                               INTERVAL 1 HOUR)) AS h
),
full_series AS (
  -- Fill missing (ZIP, hour) combinations with 0 trips
  SELECT
    g.zip_code,
    g.hr_ts,
    COALESCE(c.trips, 0) AS trips
  FROM grid AS g
  LEFT JOIN hour_counts AS c
  USING (zip_code, hr_ts)
),
metrics AS (
  -- Lagged values and moving statistics
  SELECT
    zip_code,
    hr_ts,
    trips,
    LAG(trips, 1)   OVER w AS trips_1hr_ago,
    LAG(trips, 24)  OVER w AS trips_24hr_ago,
    LAG(trips, 168) OVER w AS trips_7d_ago,
    LAG(trips, 336) OVER w AS trips_14d_ago,
    AVG(trips)        OVER (w ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS ma_14d,
    STDDEV_POP(trips) OVER (w ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS sd_14d,
    AVG(trips)        OVER (w ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS ma_21d,
    STDDEV_POP(trips) OVER (w ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS sd_21d
  FROM full_series
  WINDOW w AS (PARTITION BY zip_code ORDER BY hr_ts)
)
SELECT
  zip_code,
  hr_ts,
  trips,
  trips_1hr_ago,
  trips_24hr_ago,
  trips_7d_ago,
  trips_14d_ago,
  ma_14d,
  sd_14d,
  ma_21d,
  sd_21d
FROM metrics
WHERE DATE(hr_ts) = '2015-01-01'
ORDER BY trips DESC
LIMIT 5;