/*  Average CitiBike trips on rainy (>5 mm) vs. non‑rainy days (≤5 mm) in 2016   */

WITH
-- NYC reference point
params AS (
  SELECT ST_GEOGPOINT(-74.0060 , 40.7128) AS nyc
),

/* 1) GHCN stations within 50 km of NYC */
close_stations AS (
  SELECT
    s.id ,
    ST_DISTANCE( ST_GEOGPOINT(s.longitude , s.latitude) ,
                 (SELECT nyc FROM params) )            AS dist_m
  FROM `bigquery-public-data.ghcn_d.ghcnd_stations` AS s
  WHERE ST_DISTANCE( ST_GEOGPOINT(s.longitude , s.latitude) ,
                     (SELECT nyc FROM params) ) < 50000        -- 50 km
),

/* 2) Among those, pick the one with the most un‑flagged 2016 PRCP records */
station_quality AS (
  SELECT
    g.id ,
    COUNT(*) AS valid_days
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016` AS g
  JOIN close_stations USING (id)
  WHERE g.element = 'PRCP'
    AND g.qflag  IS NULL                     -- keep only good measurements
  GROUP BY g.id
),
best_station AS (
  SELECT id
  FROM (
    SELECT id ,
           ROW_NUMBER() OVER (ORDER BY valid_days DESC) AS rn
    FROM station_quality
  )
  WHERE rn = 1
),

/* 3) Daily precipitation totals for that best station */
daily_precip AS (
  SELECT
    DATE(date)                AS day ,
    SUM(value) / 10.0         AS precip_mm            -- tenths‑mm → mm
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
  WHERE id      IN (SELECT id FROM best_station)
    AND element = 'PRCP'
    AND qflag   IS NULL
  GROUP BY day
),

/* 4) CitiBike trip counts per day in 2016 */
daily_trips AS (
  SELECT
    DATE(starttime) AS day ,
    COUNT(*)        AS trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY day
)

/* 5) Combine & compute averages */
SELECT
  IF(p.precip_mm > 5.0 ,
     'Rainy (>5 mm)' ,
     'Non‑rainy (≤5 mm)')      AS day_type ,
  AVG(t.trips)                 AS avg_daily_trips ,
  COUNT(*)                     AS num_days
FROM daily_precip  AS p
JOIN daily_trips   AS t  USING (day)
GROUP BY day_type
ORDER BY day_type;