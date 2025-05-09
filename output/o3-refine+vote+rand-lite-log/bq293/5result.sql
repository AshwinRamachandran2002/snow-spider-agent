-- Hourly NYC yellow‑taxi activity on 1‑Jan‑2015 with time–shifted metrics
WITH trips AS (      -- 1.  Keep only trips with real coordinates and a pickup on/ before 1‑Jan‑2015
  SELECT
    TIMESTAMP_TRUNC(t.pickup_datetime , HOUR)                  AS pickup_hour ,
    z.zip_code
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2015` t
  JOIN `bigquery-public-data.geo_us_boundaries.zip_codes`   z  -- point‑in‑polygon ZIP assignment
    ON ST_CONTAINS(
         z.zip_code_geom ,
         ST_GEOGPOINT(t.pickup_longitude , t.pickup_latitude)
       )
  WHERE t.pickup_datetime BETWEEN TIMESTAMP('2014-12-11 00:00:00')
                             AND TIMESTAMP('2015-01-01 23:59:59')
    AND t.pickup_longitude IS NOT NULL  AND t.pickup_latitude IS NOT NULL
    AND t.pickup_longitude <> 0         AND t.pickup_latitude  <> 0
),

trips_per_hr AS (     -- 2.  Count trips per ZIP + hour
  SELECT
    zip_code ,
    pickup_hour                                   AS hr ,
    COUNT(*)                                      AS trip_cnt
  FROM trips
  GROUP BY zip_code , hr
),

hrs AS (              -- 3.  Every hour in the 21‑day window ending 1‑Jan‑2015
  SELECT *
  FROM UNNEST(
         GENERATE_TIMESTAMP_ARRAY('2014-12-11 00:00:00'
                                 ,'2015-01-01 23:00:00'
                                 ,INTERVAL 1 HOUR)
       ) AS hr
),

zips AS (             -- 4.  All ZIP codes that had at least one trip in the window
  SELECT DISTINCT zip_code FROM trips
),

grid AS (             -- 5.  Cross‑join to get a complete ZIP × HOUR grid
  SELECT z.zip_code , h.hr
  FROM  zips z
  CROSS JOIN hrs h
),

grid_cnt AS (         -- 6.  Attach trip counts (zeros where no trips)
  SELECT
    g.zip_code ,
    g.hr ,
    COALESCE(p.trip_cnt , 0)   AS trip_cnt
  FROM grid g
  LEFT JOIN trips_per_hr p
    ON  p.zip_code = g.zip_code
    AND p.hr       = g.hr
),

stats AS (            -- 7.  Time‑shifted features & moving stats (exclude current hour)
  SELECT
    zip_code ,
    hr ,
    trip_cnt ,
    LAG( trip_cnt ,   1) OVER w            AS trips_1h_ago ,
    LAG( trip_cnt ,  24) OVER w            AS trips_24h_ago ,
    LAG( trip_cnt , 168) OVER w            AS trips_7d_ago ,
    LAG( trip_cnt , 336) OVER w            AS trips_14d_ago ,
    AVG(       trip_cnt ) OVER (w ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS ma_14d ,
    STDDEV_SAMP(trip_cnt) OVER (w ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS sd_14d ,
    AVG(       trip_cnt ) OVER (w ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS ma_21d ,
    STDDEV_SAMP(trip_cnt) OVER (w ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS sd_21d
  FROM grid_cnt
  WINDOW w AS (PARTITION BY zip_code ORDER BY hr)
)

-- 8.  Return the 1‑Jan‑2015 hours with the highest trip counts
SELECT *
FROM   stats
WHERE  hr BETWEEN TIMESTAMP('2015-01-01 00:00:00')
             AND TIMESTAMP('2015-01-01 23:00:00')
ORDER  BY trip_cnt DESC , zip_code , hr
LIMIT 5;