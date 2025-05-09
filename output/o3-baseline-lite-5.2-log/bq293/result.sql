-- Top‑5 NYC ZIP/hours on 1‑Jan‑2015 with lagged counts
WITH
/* --- NYC ZIP polygons (rough lat/lon filter for speed) ------------------- */
nyc_zips AS (
  SELECT
    zip_code,
    zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_code = 'NY'
    AND ST_Y(ST_CENTROID(zip_code_geom)) BETWEEN 40.4 AND 41.1
    AND ST_X(ST_CENTROID(zip_code_geom)) BETWEEN -74.3 AND -73.6
),
/* --- Yellow‑cab pick‑ups on 1‑Jan‑2015 (valid coords, NYC bbox) ---------- */
trips AS (
  SELECT
    ST_GEOGPOINT(pickup_longitude, pickup_latitude)      AS pt,
    TIMESTAMP_TRUNC(pickup_datetime , HOUR)              AS hour_ts
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2015`
  WHERE DATE(pickup_datetime) = '2015-01-01'
    AND pickup_longitude BETWEEN -74.3 AND -73.6
    AND pickup_latitude  BETWEEN  40.4 AND 41.1
),
/* --- attach ZIP code via spatial join ----------------------------------- */
trips_with_zip AS (
  SELECT
    z.zip_code,
    t.hour_ts
  FROM trips t
  JOIN nyc_zips z
  ON ST_CONTAINS(z.zip_code_geom , t.pt)
),
/* --- trip counts per ZIP & hour ----------------------------------------- */
hourly_counts AS (
  SELECT
    zip_code,
    hour_ts,
    COUNT(*) AS trip_cnt
  FROM trips_with_zip
  GROUP BY zip_code, hour_ts
),
/* --- full grid of every NYC ZIP × 24 hours (fills missing with 0) -------- */
hours AS (
  SELECT TIMESTAMP '2015-01-01 00:00:00' + INTERVAL h HOUR AS hour_ts
  FROM UNNEST(GENERATE_ARRAY(0,23)) AS h
),
zip_list AS (SELECT zip_code FROM nyc_zips),
grid AS (
  SELECT z.zip_code, h.hour_ts
  FROM zip_list AS z
  CROSS JOIN hours  AS h
),
filled AS (
  SELECT
    g.zip_code,
    g.hour_ts,
    COALESCE(hc.trip_cnt,0) AS trip_cnt
  FROM grid g
  LEFT JOIN hourly_counts hc
  USING (zip_code, hour_ts)
),
/* --- lagged metrics & moving stats -------------------------------------- */
metrics AS (
  SELECT
    zip_code,
    hour_ts,
    trip_cnt,
    COALESCE(LAG(trip_cnt, 1)   OVER w, 0) AS cnt_1h_ago,
    COALESCE(LAG(trip_cnt, 24)  OVER w, 0) AS cnt_24h_ago,
    COALESCE(LAG(trip_cnt, 168) OVER w, 0) AS cnt_7d_ago,
    COALESCE(LAG(trip_cnt, 336) OVER w, 0) AS cnt_14d_ago,
    AVG(trip_cnt)         OVER (w ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS ma_14d,
    STDDEV_SAMP(trip_cnt) OVER (w ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS sd_14d,
    AVG(trip_cnt)         OVER (w ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS ma_21d,
    STDDEV_SAMP(trip_cnt) OVER (w ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS sd_21d
  FROM filled
  WINDOW w AS (PARTITION BY zip_code ORDER BY hour_ts)
)
/* --- final top‑5 ZIP/hour combinations ---------------------------------- */
SELECT *
FROM metrics
ORDER BY trip_cnt DESC, zip_code, hour_ts
LIMIT 5;