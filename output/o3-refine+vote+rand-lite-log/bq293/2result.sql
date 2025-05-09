-- ────────────────────────────────────────────────────────────────────────────────
-- Hour‑by‑hour NYC yellow‑taxi demand on 1‑Jan‑2015 with temporal features
-- ────────────────────────────────────────────────────────────────────────────────
WITH nyc_zip AS (   -- all NY State ZIP polygons (incl. the five boroughs)
  SELECT
    zip_code,
    zip_code_geom
  FROM  `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_code = 'NY'
),

hours_jan1 AS (     -- the 24 hourly buckets of 1‑Jan‑2015  (UTC in source data)
  SELECT
    TIMESTAMP '2015-01-01 00:00:00+00' + INTERVAL h HOUR AS hour_ts
  FROM UNNEST(GENERATE_ARRAY(0,23)) AS h
),

grid AS (           -- every combination of NY ZIP × hour  (guarantees zero rows)
  SELECT
    z.zip_code,
    h.hour_ts
  FROM nyc_zip AS z
  CROSS JOIN hours_jan1 AS h
),

trip_counts AS (    -- observed trip counts for the day / ZIP / hour
  SELECT
    z.zip_code,
    TIMESTAMP_TRUNC(t.pickup_datetime , HOUR) AS hour_ts,
    COUNT(*)                                    AS trip_count
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2015`  AS t
  JOIN nyc_zip AS z
    ON ST_CONTAINS(z.zip_code_geom ,
                   ST_GEOGPOINT(t.pickup_longitude , t.pickup_latitude))
  WHERE t.pickup_datetime >= '2015-01-01 00:00:00'
    AND t.pickup_datetime <  '2015-01-02 00:00:00'
    AND t.pickup_latitude  IS NOT NULL AND t.pickup_longitude IS NOT NULL
    AND t.pickup_latitude  <> 0       AND t.pickup_longitude <> 0
  GROUP BY z.zip_code , hour_ts
),

full_counts AS (    -- fill in the zero‑trip hours
  SELECT
    g.zip_code,
    g.hour_ts,
    COALESCE(tc.trip_count ,0) AS trip_count
  FROM grid AS g
  LEFT JOIN trip_counts AS tc
    USING (zip_code , hour_ts)
),

lags AS (           -- add lagged counters for required look‑back offsets
  SELECT
    fc.* ,
    COALESCE(l1.trip_count  ,0) AS trips_1h_ago ,
    COALESCE(l24.trip_count ,0) AS trips_24h_ago ,
    COALESCE(l168.trip_count,0) AS trips_168h_ago ,
    COALESCE(l336.trip_count,0) AS trips_336h_ago
  FROM full_counts AS fc
  LEFT JOIN full_counts AS l1
         ON l1.zip_code = fc.zip_code
        AND l1.hour_ts  = fc.hour_ts - INTERVAL 1   HOUR
  LEFT JOIN full_counts AS l24
         ON l24.zip_code = fc.zip_code
        AND l24.hour_ts  = fc.hour_ts - INTERVAL 24  HOUR
  LEFT JOIN full_counts AS l168
         ON l168.zip_code = fc.zip_code
        AND l168.hour_ts  = fc.hour_ts - INTERVAL 168 HOUR
  LEFT JOIN full_counts AS l336
         ON l336.zip_code = fc.zip_code
        AND l336.hour_ts  = fc.hour_ts - INTERVAL 336 HOUR
),

final AS (          -- moving averages / stdevs (exclude current hour)
  SELECT
    zip_code ,
    hour_ts ,
    trip_count ,
    trips_1h_ago ,
    trips_24h_ago ,
    trips_168h_ago ,
    trips_336h_ago ,
    AVG( trip_count ) OVER (
         PARTITION BY zip_code
         ORDER BY hour_ts
         ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING)  AS mov_avg_14d ,
    STDDEV_SAMP( trip_count ) OVER (
         PARTITION BY zip_code
         ORDER BY hour_ts
         ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS mov_stddev_14d ,
    AVG( trip_count ) OVER (
         PARTITION BY zip_code
         ORDER BY hour_ts
         ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING)  AS mov_avg_21d ,
    STDDEV_SAMP( trip_count ) OVER (
         PARTITION BY zip_code
         ORDER BY hour_ts
         ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS mov_stddev_21d
  FROM lags
)

SELECT *
FROM   final
ORDER  BY trip_count DESC , zip_code , hour_ts
LIMIT  5;