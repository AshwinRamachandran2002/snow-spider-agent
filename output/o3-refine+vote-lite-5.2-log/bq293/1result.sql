--+---------------------------------------------+
--|  NYC Yellow‑cab trips on 1‑Jan‑2015 by ZIP  |
--|  plus hourly lags & moving‑window metrics  |
--+---------------------------------------------+
WITH
/* ---------- 1.  Keep only valid Jan‑01‑2015 trips with good coordinates ---------- */
valid_trips AS (
  SELECT
    TIMESTAMP_TRUNC(pickup_datetime , HOUR)          AS hour_ts ,
    ST_GEOGPOINT(pickup_longitude , pickup_latitude) AS pt
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2015`
  WHERE pickup_datetime >= '2015-01-01 00:00:00'
    AND pickup_datetime <  '2015-01-02 00:00:00'
    AND pickup_longitude IS NOT NULL AND pickup_latitude IS NOT NULL
    AND pickup_longitude != 0      AND pickup_latitude  != 0
),

/* ---------- 2.  Attach each trip to the ZIP it falls in ---------- */
trip_zips AS (
  SELECT
    z.zip_code ,
    v.hour_ts
  FROM valid_trips v
  JOIN `bigquery-public-data.geo_us_boundaries.zip_codes` z
    ON ST_CONTAINS(z.zip_code_geom , v.pt)
),

/* ---------- 3.  Aggregate trips per ZIP + hour ---------- */
agg AS (
  SELECT
    zip_code ,
    hour_ts ,
    COUNT(*) AS trip_count
  FROM trip_zips
  GROUP BY zip_code , hour_ts
),

/* ---------- 4.  Build the full set of hours (24) and NYC ZIPs ---------- */
hours AS (
  SELECT hour_ts
  FROM UNNEST(
        GENERATE_TIMESTAMP_ARRAY('2015-01-01 00:00:00',
                                 '2015-01-01 23:00:00',
                                 INTERVAL 1 HOUR)
       ) AS hour_ts
),
nyc_zips AS (             -- all NY‑state ZIP codes whose centroid lies in the NYC bbox
  SELECT DISTINCT zip_code
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_name = 'New York'
    AND ST_WITHIN(
          ST_CENTROID(zip_code_geom),
          ST_GEOGFROMTEXT('POLYGON((-74.3 40.45, -73.6 40.45, -73.6 40.95, -74.3 40.95, -74.3 40.45))')
        )
),

/* ---------- 5.  Produce ZIP × hour grid and bring in counts (0 when missing) ------ */
grid AS (
  SELECT z.zip_code , h.hour_ts
  FROM nyc_zips z CROSS JOIN hours h
),
grid_counts AS (
  SELECT
    g.zip_code ,
    g.hour_ts ,
    COALESCE(a.trip_count , 0) AS trip_count
  FROM grid g
  LEFT JOIN agg a
    ON a.zip_code = g.zip_code
   AND a.hour_ts = g.hour_ts
),

/* ---------- 6.  Lag metrics & moving windows (excludes current hour) -------------- */
metrics AS (
  SELECT
    zip_code ,
    hour_ts ,
    trip_count ,

    LAG(trip_count ,   1) OVER w AS trips_1h_ago ,
    LAG(trip_count ,  24) OVER w AS trips_24h_ago ,
    LAG(trip_count , 168) OVER w AS trips_168h_ago ,
    LAG(trip_count , 336) OVER w AS trips_336h_ago ,

    AVG(trip_count)      OVER w_14 AS avg_14d ,
    STDDEV_POP(trip_count) OVER w_14 AS stddev_14d ,

    AVG(trip_count)      OVER w_21 AS avg_21d ,
    STDDEV_POP(trip_count) OVER w_21 AS stddev_21d

  FROM grid_counts

  WINDOW
    w      AS (PARTITION BY zip_code ORDER BY hour_ts),
    w_14   AS (PARTITION BY zip_code ORDER BY hour_ts
               ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING),   -- 14×24
    w_21   AS (PARTITION BY zip_code ORDER BY hour_ts
               ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING)    -- 21×24
)

/* ---------- 7.  Return the 5 ZIP‑hour groups with the most trips ----------------- */
SELECT *
FROM metrics
ORDER BY trip_count DESC, zip_code, hour_ts
LIMIT 5;