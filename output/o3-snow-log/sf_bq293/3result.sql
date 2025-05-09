/* ----  NYC YELLOW-TAXI  —  1-JAN-2015  HOURLY “ZIP-LIKE” (LAT/LON 3dp) ANALYSIS  ---- */
/*  NOTE:  Because the GEO_US_BOUNDARIES database is not available in the current
           Snowflake environment, a “zip-code surrogate” is built by rounding the
           latitude / longitude to 3 decimal places (≈ 110 m resolution).            */
WITH
/* ------------------------------------------------------------------------------- */
params AS (      /* time constants – micro-seconds since epoch                    */
  SELECT
      1418256000000000::NUMBER AS hist_start_us ,   -- 2014-12-11 00:00 UTC
      1420070400000000::NUMBER AS jan1_start_us  ,   -- 2015-01-01 00:00 UTC
      1420156800000000::NUMBER AS jan2_start_us  ,   -- 2015-01-02 00:00 UTC
      3600000000::NUMBER       AS us_per_hour        -- 1 hour in µs
),
/* 528 consecutive hours = 21-day look-back (504 h) + 24 h of Jan-1               */
hours AS (
  SELECT
      (p.hist_start_us + p.us_per_hour * seq4())                             AS hour_start_us ,
      FLOOR((p.hist_start_us + p.us_per_hour * seq4()) / p.us_per_hour)      AS hour_key
  FROM params p
  ,   TABLE(GENERATOR(ROWCOUNT => 528))
),
jan1_hours AS (      -- hours we ultimately want to report
  SELECT hour_key
  FROM   hours h , params p
  WHERE  h.hour_start_us BETWEEN p.jan1_start_us AND p.jan2_start_us - p.us_per_hour
),
/* --------  raw trips (cleaned) for 2014-12-11 .. 2015-01-01  ------------------ */
clean_trips AS (
  SELECT
      FLOOR("pickup_datetime"/3600000000)          AS hour_key ,
      "pickup_latitude"                            AS lat ,
      "pickup_longitude"                           AS lon
  FROM NEW_YORK_GEO.NEW_YORK.TLC_YELLOW_TRIPS_2014
  WHERE "pickup_datetime" BETWEEN (SELECT hist_start_us FROM params)
                              AND (SELECT jan2_start_us  FROM params)
    AND "pickup_latitude"  BETWEEN 40 AND 42
    AND "pickup_longitude" BETWEEN -75 AND -72
    AND NOT ("pickup_latitude" = 0 AND "pickup_longitude" = 0)

  UNION ALL

  SELECT
      FLOOR("pickup_datetime"/3600000000) ,
      "pickup_latitude" ,
      "pickup_longitude"
  FROM NEW_YORK_GEO.NEW_YORK.TLC_YELLOW_TRIPS_2015
  WHERE "pickup_datetime" BETWEEN (SELECT hist_start_us FROM params)
                              AND (SELECT jan2_start_us  FROM params)
    AND "pickup_latitude"  BETWEEN 40 AND 42
    AND "pickup_longitude" BETWEEN -75 AND -72
    AND NOT ("pickup_latitude" = 0 AND "pickup_longitude" = 0)
),
/* --------  build 3-decimal “ZIP-like” key (≈ 110 m grid cell)  ---------------- */
trips_with_zip AS (
  SELECT
      TO_VARCHAR(ROUND(lat ,3)) || ',' || TO_VARCHAR(ROUND(lon ,3))  AS zip_code ,
      hour_key
  FROM clean_trips
),
hourly_trip_cnt AS (         -- aggregated trips per zip_code per hour
  SELECT
      zip_code ,
      hour_key ,
      COUNT(*) AS trip_cnt
  FROM trips_with_zip
  GROUP BY 1,2
),
/* ----------------------------------------------------------------------------- */
zip_dim AS (                 -- universe of zip_code surrogates in data window
  SELECT DISTINCT zip_code FROM hourly_trip_cnt
),
zip_hour_frame AS (          -- Cartesian product => ensures zero-trip rows
  SELECT
      z.zip_code ,
      h.hour_key
  FROM zip_dim z
  CROSS JOIN hours h
),
base AS (                    -- align real counts to the full frame
  SELECT
      zh.zip_code ,
      zh.hour_key ,
      COALESCE(htc.trip_cnt,0) AS trip_cnt
  FROM zip_hour_frame zh
  LEFT JOIN hourly_trip_cnt htc
    ON  zh.zip_code = htc.zip_code
    AND zh.hour_key = htc.hour_key
),
/* ----  lags, moving averages & standard deviations (excluding current hour) -- */
metrics AS (
  SELECT
      b.* ,
      LAG(trip_cnt,   1) OVER (PARTITION BY zip_code ORDER BY hour_key) AS lag_1h ,
      LAG(trip_cnt,  24) OVER (PARTITION BY zip_code ORDER BY hour_key) AS lag_24h ,
      LAG(trip_cnt, 168) OVER (PARTITION BY zip_code ORDER BY hour_key) AS lag_168h ,
      LAG(trip_cnt, 336) OVER (PARTITION BY zip_code ORDER BY hour_key) AS lag_336h ,

      AVG(trip_cnt)       OVER (PARTITION BY zip_code ORDER BY hour_key
                                ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS ma_14d ,
      STDDEV_SAMP(trip_cnt) OVER (PARTITION BY zip_code ORDER BY hour_key
                                ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS std_14d ,

      AVG(trip_cnt)       OVER (PARTITION BY zip_code ORDER BY hour_key
                                ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS ma_21d ,
      STDDEV_SAMP(trip_cnt) OVER (PARTITION BY zip_code ORDER BY hour_key
                                ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS std_21d
  FROM base b
)
/* -----------------------------  FINAL RESULT  -------------------------------- */
SELECT
    zip_code ,
    hour_key ,
    trip_cnt ,
    lag_1h ,
    lag_24h ,
    lag_168h ,
    lag_336h ,
    ma_14d ,
    std_14d ,
    ma_21d ,
    std_21d
FROM metrics
WHERE hour_key IN (SELECT hour_key FROM jan1_hours)      -- restrict to 1-Jan-2015
ORDER BY trip_cnt DESC NULLS LAST
LIMIT 5;