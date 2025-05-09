-- ──────────────────────────────────────────────────────────────────────────────
-- Hour‑by‑hour NYC yellow‑cab activity for 01‑Jan‑2015 with lag & moving stats
-- ----------------------------------------------------------------------------
WITH nyc_zips AS (   -- Only NY State ZIP polygons
  SELECT
    zip_code,
    zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_code = 'NY'
),

-- ── 1.  Filter trips to 1‑Jan‑2015 that have valid coordinates and map them
--        to a NYC ZIP Code polygon (pickup point ∈ ZIP polygon)
mapped_trips AS (
  SELECT
    TIMESTAMP_TRUNC(pickup_datetime, HOUR)  AS hr,
    z.zip_code
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2015` AS t
  JOIN nyc_zips AS z
    ON ST_CONTAINS(
         z.zip_code_geom,
         ST_GEOGPOINT(t.pickup_longitude, t.pickup_latitude)
       )
  WHERE t.pickup_datetime >= '2015-01-01 00:00:00'
    AND t.pickup_datetime <  '2015-01-02 00:00:00'         -- 01‑Jan‑2015 only
    AND t.pickup_longitude IS NOT NULL
    AND t.pickup_latitude  IS NOT NULL
    AND t.pickup_longitude != 0
    AND t.pickup_latitude  != 0
),

-- ── 2.  Hourly trip counts actually observed
hourly_counts AS (
  SELECT
    zip_code,
    hr,
    COUNT(*) AS trip_count
  FROM mapped_trips
  GROUP BY zip_code, hr
),

-- ── 3.  Produce *all* combinations of every NYC ZIP with every hour of the day
all_hours AS (
  SELECT hr
  FROM UNNEST(
         GENERATE_TIMESTAMP_ARRAY(
           '2015-01-01 00:00:00',
           '2015-01-01 23:00:00',
           INTERVAL 1 HOUR)
       ) AS hr
),
all_zip_hours AS (
  SELECT z.zip_code, h.hr
  FROM (SELECT DISTINCT zip_code FROM nyc_zips) AS z
  CROSS JOIN all_hours                  AS h
),

-- ── 4.  Fill in zeros where no trips occurred
zip_hour_matrix AS (
  SELECT
    a.zip_code,
    a.hr,
    IFNULL(c.trip_count, 0) AS trip_count
  FROM all_zip_hours AS a
  LEFT JOIN hourly_counts AS c
  USING (zip_code, hr)
),

-- ── 5.  Calculate requested lagged counts and moving statistics
metrics AS (
  SELECT
    zip_code,
    hr,
    trip_count,
    LAG(trip_count,   1) OVER (PARTITION BY zip_code ORDER BY hr) AS trips_1h_ago,
    LAG(trip_count,  24) OVER (PARTITION BY zip_code ORDER BY hr) AS trips_24h_ago,
    LAG(trip_count, 168) OVER (PARTITION BY zip_code ORDER BY hr) AS trips_168h_ago,
    LAG(trip_count, 336) OVER (PARTITION BY zip_code ORDER BY hr) AS trips_336h_ago,
    -- 14‑day (336‑hour) moving window, excluding current hour
    AVG(trip_count)         OVER (PARTITION BY zip_code ORDER BY hr
                                  ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS avg_14d,
    STDDEV_SAMP(trip_count) OVER (PARTITION BY zip_code ORDER BY hr
                                  ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS stddev_14d,
    -- 21‑day (504‑hour) moving window, excluding current hour
    AVG(trip_count)         OVER (PARTITION BY zip_code ORDER BY hr
                                  ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS avg_21d,
    STDDEV_SAMP(trip_count) OVER (PARTITION BY zip_code ORDER BY hr
                                  ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS stddev_21d
  FROM zip_hour_matrix
)

-- ── 6.  Return the TOP‑5 ZIP/hour combinations by trip volume
SELECT *
FROM   metrics
ORDER  BY trip_count DESC, zip_code, hr
LIMIT  5;