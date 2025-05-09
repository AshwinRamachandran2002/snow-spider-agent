-- Hour‑by‑hour NYC yellow‑cab activity for 1‑Jan‑2015 with lag metrics
WITH
/* ----------------------------------------------------------  
   1. All NYC ZIP codes
---------------------------------------------------------- */
zips AS (
  SELECT DISTINCT zip_code
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_code = 'NY'
),

/* ----------------------------------------------------------  
   2. Hourly trip counts for the 21‑day history  
      (2014‑12‑11 00:00 UTC  →  2015‑01‑01 23:59 UTC)
---------------------------------------------------------- */
hourly_trips AS (
  SELECT
    TIMESTAMP_TRUNC(pickup_datetime, HOUR) AS hour_ts,
    z.zip_code                              AS zip_code,
    COUNT(*)                                AS trips
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2015` t
  JOIN `bigquery-public-data.geo_us_boundaries.zip_codes`  z
    ON ST_CONTAINS(z.zip_code_geom,
                   ST_GEOGPOINT(t.pickup_longitude,
                                 t.pickup_latitude))
  WHERE
        pickup_datetime >= TIMESTAMP('2014-12-11 00:00:00')
    AND pickup_datetime <  TIMESTAMP('2015-01-02 00:00:00')
    AND t.pickup_latitude  IS NOT NULL  AND t.pickup_latitude  != 0
    AND t.pickup_longitude IS NOT NULL  AND t.pickup_longitude != 0
    AND z.state_code = 'NY'
  GROUP BY hour_ts, zip_code
),

/* ----------------------------------------------------------  
   3. Dense hour×ZIP skeleton (ensures zeros)
---------------------------------------------------------- */
full_grid AS (
  SELECT *
  FROM UNNEST(
         GENERATE_TIMESTAMP_ARRAY('2014-12-11 00:00:00',
                                  '2015-01-01 23:00:00',
                                  INTERVAL 1 HOUR)
       ) AS hour_ts
  CROSS JOIN zips
),

/* ----------------------------------------------------------  
   4. Hourly series per ZIP with zero‑fill
---------------------------------------------------------- */
series AS (
  SELECT
    g.zip_code,
    g.hour_ts,
    COALESCE(t.trips, 0) AS trip_cnt
  FROM full_grid g
  LEFT JOIN hourly_trips t
    USING (zip_code, hour_ts)
)

/* ----------------------------------------------------------  
   5. Add lags & moving stats; keep only 1‑Jan‑2015 hours
---------------------------------------------------------- */
SELECT
  zip_code,
  hour_ts,
  trip_cnt,

  -- simple lags
  LAG(trip_cnt, 1  )  OVER w AS cnt_1h_ago,
  LAG(trip_cnt, 24 )  OVER w AS cnt_24h_ago,
  LAG(trip_cnt, 168)  OVER w AS cnt_7d_ago,
  LAG(trip_cnt, 336)  OVER w AS cnt_14d_ago,

  -- moving averages / std‑devs (exclude current hour)
  AVG(trip_cnt)       OVER w_14d AS ma_14d,
  STDDEV_POP(trip_cnt)OVER w_14d AS std_14d,
  AVG(trip_cnt)       OVER w_21d AS ma_21d,
  STDDEV_POP(trip_cnt)OVER w_21d AS std_21d

FROM series
WHERE hour_ts BETWEEN TIMESTAMP('2015-01-01 00:00:00')
                  AND TIMESTAMP('2015-01-01 23:00:00')

WINDOW
  w     AS (PARTITION BY zip_code ORDER BY hour_ts),
  w_14d AS (PARTITION BY zip_code ORDER BY hour_ts
            ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING),   -- 14×24
  w_21d AS (PARTITION BY zip_code ORDER BY hour_ts
            ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING)    -- 21×24

ORDER BY trip_cnt DESC, zip_code, hour_ts
LIMIT 5;