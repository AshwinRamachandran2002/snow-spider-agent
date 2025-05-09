WITH nyc_zips AS (                     -- NYC ZIP polygons
  SELECT
    zip_code,
    zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_code = 'NY'
    AND ST_INTERSECTS(
          zip_code_geom,
          ST_GEOGFROMTEXT(
            'POLYGON((-74.3 40.5, -73.7 40.5, -73.7 40.9, -74.3 40.9, -74.3 40.5))')
        )
),
-- bring in 21‑day history (Dec‑11‑2014 ⟶ Jan‑01‑2015) to support all lags / MAs
raw_trips AS (
  SELECT pickup_datetime, pickup_longitude, pickup_latitude
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2015`
  WHERE pickup_datetime <= '2015-01-01 23:59:59+00'
  UNION ALL
  SELECT pickup_datetime, pickup_longitude, pickup_latitude
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2014`
  WHERE pickup_datetime >= '2014-12-11 00:00:00+00'
),
-- hourly trip counts per ZIP (only valid NYC coords)
trip_hours AS (
  SELECT
    z.zip_code,
    TIMESTAMP_TRUNC(t.pickup_datetime, HOUR) AS hour_start,
    COUNT(*) AS trip_count
  FROM raw_trips AS t
  JOIN nyc_zips AS z
    ON ST_CONTAINS(z.zip_code_geom,
                   ST_GEOGPOINT(t.pickup_longitude, t.pickup_latitude))
  WHERE t.pickup_longitude BETWEEN -74.3 AND -73.7
    AND t.pickup_latitude  BETWEEN  40.5 AND  40.9
    AND t.pickup_longitude IS NOT NULL
    AND t.pickup_latitude  IS NOT NULL
  GROUP BY z.zip_code, hour_start
),
-- build dense hour‑by‑ZIP grid (fills missing hours with 0 trips)
grid AS (
  SELECT
    z.zip_code,
    h AS hour_start
  FROM (SELECT DISTINCT zip_code FROM trip_hours) AS z
  CROSS JOIN UNNEST(
           GENERATE_TIMESTAMP_ARRAY('2014-12-11 00:00:00+00',
                                    '2015-01-01 23:00:00+00',
                                    INTERVAL 1 HOUR)
         ) AS h
),
joined AS (
  SELECT
    g.zip_code,
    g.hour_start,
    COALESCE(th.trip_count, 0) AS trip_count
  FROM grid AS g
  LEFT JOIN trip_hours AS th
    ON th.zip_code   = g.zip_code
   AND th.hour_start = g.hour_start
),
calc AS (                               -- compute lags & moving statistics
  SELECT
    zip_code,
    hour_start,
    trip_count,
    LAG(trip_count, 1)   OVER w AS lag_1h,
    LAG(trip_count, 24)  OVER w AS lag_24h,
    LAG(trip_count, 168) OVER w AS lag_168h,
    LAG(trip_count, 336) OVER w AS lag_336h,
    AVG(trip_count)        OVER w14 AS ma_14d,
    STDDEV_POP(trip_count) OVER w14 AS sd_14d,
    AVG(trip_count)        OVER w21 AS ma_21d,
    STDDEV_POP(trip_count) OVER w21 AS sd_21d
  FROM joined
  WINDOW
    w   AS (PARTITION BY zip_code ORDER BY hour_start),
    w14 AS (PARTITION BY zip_code ORDER BY hour_start
            ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING),
    w21 AS (PARTITION BY zip_code ORDER BY hour_start
            ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING)
)
-- 1‑Jan‑2015 results, top‑5 rows by trip count
SELECT
  zip_code,
  hour_start,
  trip_count,
  COALESCE(lag_1h,   0) AS lag_1h,
  COALESCE(lag_24h,  0) AS lag_24h,
  COALESCE(lag_168h, 0) AS lag_168h,
  COALESCE(lag_336h, 0) AS lag_336h,
  ROUND(ma_14d, 4) AS ma_14d,
  ROUND(ma_21d, 4) AS ma_21d,
  ROUND(sd_14d, 4) AS sd_14d,
  ROUND(sd_21d, 4) AS sd_21d
FROM calc
WHERE DATE(hour_start) = '2015-01-01'
ORDER BY trip_count DESC, zip_code, hour_start
LIMIT 5;