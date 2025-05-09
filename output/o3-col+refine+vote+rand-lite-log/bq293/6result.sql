-- Top-5 NYC ZIP-code / hour combinations on 1-Jan-2015 together with
-- lagged counts and rolling statistics, built from yellow-cab trips.

WITH trips AS (   -- map trips to a NY ZIP + NY-local hour
  SELECT
    z.zip_code,
    DATETIME_TRUNC(DATETIME(t.pickup_datetime,'America/New_York'),HOUR) AS hr
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2015` t
  JOIN `bigquery-public-data.geo_us_boundaries.zip_codes` z
    ON  z.state_code = 'NY'
   AND ST_CONTAINS(
         z.zip_code_geom,
         ST_GEOGPOINT(t.pickup_longitude,t.pickup_latitude)
       )
  WHERE DATE(DATETIME(t.pickup_datetime,'America/New_York'))
          BETWEEN '2014-12-11'         -- 21-day look-back for stats
              AND '2015-01-01'
    AND t.pickup_longitude IS NOT NULL AND t.pickup_latitude IS NOT NULL
    AND t.pickup_longitude <> 0        AND t.pickup_latitude  <> 0
),
hourly_counts AS (   -- trips per (zip,hour)
  SELECT
    zip_code,
    hr,
    COUNT(*) AS trip_cnt
  FROM trips
  GROUP BY zip_code, hr
),
complete_hours AS (  -- full ZIP × hour grid for the study period
  SELECT
    z.zip_code,
    CAST(ts AS DATETIME) AS hr
  FROM (SELECT DISTINCT zip_code FROM hourly_counts) z
  CROSS JOIN UNNEST(
         GENERATE_TIMESTAMP_ARRAY('2014-12-11 00:00:00',
                                  '2015-01-01 23:00:00',
                                  INTERVAL 1 HOUR)
       ) AS ts
),
filled AS (          -- insert 0 where no trips
  SELECT
    c.zip_code,
    c.hr,
    COALESCE(h.trip_cnt,0) AS trip_cnt
  FROM complete_hours c
  LEFT JOIN hourly_counts h USING (zip_code,hr)
),
stats AS (           -- lags and rolling metrics
  SELECT
    zip_code,
    hr,
    trip_cnt,
    LAG(trip_cnt,   1) OVER w  AS cnt_1h_ago,
    LAG(trip_cnt,  24) OVER w  AS cnt_1d_ago,
    LAG(trip_cnt, 168) OVER w  AS cnt_7d_ago,
    LAG(trip_cnt, 336) OVER w  AS cnt_14d_ago,
    AVG(trip_cnt)        OVER w14 AS ma_14d,
    STDDEV_POP(trip_cnt) OVER w14 AS sd_14d,
    AVG(trip_cnt)        OVER w21 AS ma_21d,
    STDDEV_POP(trip_cnt) OVER w21 AS sd_21d
  FROM filled
  WINDOW
    w   AS (PARTITION BY zip_code ORDER BY hr),
    w14 AS (PARTITION BY zip_code ORDER BY hr
            ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING),   -- 14 days
    w21 AS (PARTITION BY zip_code ORDER BY hr
            ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING)    -- 21 days
)
SELECT *
FROM stats
WHERE DATE(hr) = '2015-01-01'
ORDER BY trip_cnt DESC
LIMIT 5;