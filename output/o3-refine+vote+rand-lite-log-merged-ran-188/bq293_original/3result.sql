-- NYC yellow‑cab activity on 1 Jan 2015 with lagged & rolling‑window metrics
WITH
-- 1.  Trips on the target day that have valid coordinates
trips AS (
  SELECT
    TIMESTAMP_TRUNC(pickup_datetime, HOUR)              AS hour_ts ,
    z.zip_code                                          AS zip_code ,
    COUNT(*)                                            AS trip_cnt
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2015`   t
  JOIN `bigquery-public-data.geo_us_boundaries.zip_codes`      z
    ON z.state_code = 'NY'                                           -- NY State
   AND ST_CONTAINS(z.zip_code_geom ,
                   ST_GEOGPOINT(t.pickup_longitude , t.pickup_latitude))
  WHERE pickup_datetime >= '2015-01-01 00:00:00'
    AND pickup_datetime <  '2015-01-02 00:00:00'
    AND t.pickup_longitude IS NOT NULL AND t.pickup_latitude IS NOT NULL
    AND t.pickup_longitude != 0      AND t.pickup_latitude  != 0
  GROUP BY hour_ts , zip_code
),

-- 2.  Every NYC zip code that had ≥1 trip that day
zip_list AS (
  SELECT DISTINCT zip_code FROM trips
),

-- 3.  Every hour of 1 Jan 2015
hour_list AS (
  SELECT hour_ts
  FROM UNNEST(GENERATE_TIMESTAMP_ARRAY('2015-01-01 00:00:00',
                                       '2015-01-01 23:00:00',
                                       INTERVAL 1 HOUR)) AS hour_ts
),

-- 4.  Cross‑product:  all (zip_code , hour) pairs for the day
grid AS (
  SELECT h.hour_ts , z.zip_code
  FROM hour_list h
  CROSS JOIN zip_list z
),

-- 5.  Hourly trip counts, filling missing pairs with 0
hourly AS (
  SELECT
    g.zip_code ,
    g.hour_ts ,
    IFNULL(t.trip_cnt , 0) AS trip_cnt
  FROM grid  g
  LEFT JOIN trips t
    ON t.zip_code = g.zip_code
   AND t.hour_ts = g.hour_ts
),

-- 6.  Lagged counts & rolling  averages / std‑devs (excluding current hour)
metrics AS (
  SELECT
    zip_code ,
    hour_ts ,
    trip_cnt ,

    LAG(trip_cnt ,  1)  OVER (PARTITION BY zip_code ORDER BY hour_ts) AS cnt_1h_ago ,
    LAG(trip_cnt , 24)  OVER (PARTITION BY zip_code ORDER BY hour_ts) AS cnt_24h_ago ,
    LAG(trip_cnt ,168)  OVER (PARTITION BY zip_code ORDER BY hour_ts) AS cnt_168h_ago ,
    LAG(trip_cnt ,336)  OVER (PARTITION BY zip_code ORDER BY hour_ts) AS cnt_336h_ago ,

    AVG(trip_cnt) OVER (PARTITION BY zip_code ORDER BY hour_ts
                        ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS ma_14d ,
    STDDEV_SAMP(trip_cnt) OVER (PARTITION BY zip_code ORDER BY hour_ts
                                ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS sd_14d ,

    AVG(trip_cnt) OVER (PARTITION BY zip_code ORDER BY hour_ts
                        ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS ma_21d ,
    STDDEV_SAMP(trip_cnt) OVER (PARTITION BY zip_code ORDER BY hour_ts
                                ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS sd_21d
  FROM hourly
)

-- 7.  Top‑5 (zip_code , hour) rows by trip volume
SELECT *
FROM   metrics
ORDER  BY trip_cnt DESC , zip_code , hour_ts
LIMIT 5;