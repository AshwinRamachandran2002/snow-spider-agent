-- Hourly yellow‑cab demand on 1‑Jan‑2015 with lags & moving stats
WITH trip_counts AS (      -- valid pick‑ups (sane coordinates) mapped to ZIPs
  SELECT
      z.zip_code,
      TIMESTAMP_TRUNC(t.pickup_datetime , HOUR) AS hour_ts,
      COUNT(*)                                  AS trips
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2015` t
  JOIN `bigquery-public-data.geo_us_boundaries.zip_codes` z
    ON  ST_CONTAINS(
         z.zip_code_geom,
         ST_GEOGPOINT(t.pickup_longitude , t.pickup_latitude)
       )
  WHERE t.pickup_latitude  BETWEEN -90  AND  90     -- keep only valid coordinates
    AND t.pickup_longitude BETWEEN -180 AND 180
  GROUP BY z.zip_code, hour_ts
),
zips AS (                     -- ZIPs that had at least one trip
  SELECT DISTINCT zip_code FROM trip_counts
),
hours AS (                    -- every hour on 1‑Jan‑2015 (UTC)
  SELECT ts AS hour_ts
  FROM UNNEST(
        GENERATE_TIMESTAMP_ARRAY('2015-01-01 00:00:00 UTC',
                                 '2015-01-01 23:00:00 UTC',
                                 INTERVAL 1 HOUR)
       ) AS ts
),
zip_hour_grid AS (            -- cross‑product to guarantee zero rows
  SELECT z.zip_code, h.hour_ts
  FROM  zips z  CROSS JOIN hours h
),
series AS (                   -- fill missing with 0
  SELECT
      g.zip_code,
      g.hour_ts,
      IFNULL(t.trips, 0) AS trips
  FROM zip_hour_grid g
  LEFT JOIN trip_counts t
    ON  t.zip_code = g.zip_code
    AND t.hour_ts = g.hour_ts
),
metrics AS (                  -- lags & rolling metrics
  SELECT
      zip_code,
      hour_ts,
      trips,

      COALESCE( LAG(trips,   1) OVER w, 0) AS trips_1h_ago,
      COALESCE( LAG(trips,  24) OVER w, 0) AS trips_24h_ago,
      COALESCE( LAG(trips, 168) OVER w, 0) AS trips_168h_ago,
      COALESCE( LAG(trips, 336) OVER w, 0) AS trips_336h_ago,

      AVG(trips)       OVER w14                  AS avg_14d,
      STDDEV_POP(trips) OVER w14                 AS stddev_14d,
      AVG(trips)       OVER w21                  AS avg_21d,
      STDDEV_POP(trips) OVER w21                 AS stddev_21d
  FROM series
  WINDOW
      w   AS (PARTITION BY zip_code ORDER BY hour_ts),
      w14 AS (PARTITION BY zip_code ORDER BY hour_ts
               ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING),
      w21 AS (PARTITION BY zip_code ORDER BY hour_ts
               ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING)
)
SELECT *
FROM   metrics
ORDER  BY trips DESC, zip_code, hour_ts
LIMIT  5;