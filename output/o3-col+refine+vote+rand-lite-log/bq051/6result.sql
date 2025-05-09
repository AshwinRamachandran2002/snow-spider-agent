-- Average Citi Bike daily trips in 2016 split into “Rainy” (> 5 mm) vs
-- “Non-rainy” days, using the nearest GHCN station (≤ 50 km from
-- 40.7128 N, -74.0060 E) that has valid 2016 precipitation records.

WITH nyc_center AS (
  SELECT 40.7128 AS lat , -74.0060 AS lon
),

/* 1. Stations within 50 km of NYC centre */
nearby_stations AS (
  SELECT
    s.id,
    ST_DISTANCE( ST_GEOGPOINT(s.longitude, s.latitude),
                 ST_GEOGPOINT(n.lon , n.lat) ) AS dist_m
  FROM `bigquery-public-data.ghcn_d.ghcnd_stations` s
  CROSS JOIN nyc_center n
  WHERE ST_DISTANCE( ST_GEOGPOINT(s.longitude, s.latitude),
                     ST_GEOGPOINT(n.lon , n.lat) ) <= 50000        -- 50 km
),

/* 2. Pick the closest station that actually has un-flagged 2016 PRCP data */
station_choice AS (
  SELECT ns.id
  FROM nearby_stations ns
  JOIN `bigquery-public-data.ghcn_d.ghcnd_2016` d
    ON d.id = ns.id
   AND d.element = 'PRCP'
   AND d.qflag IS NULL
  GROUP BY ns.id, ns.dist_m
  ORDER BY ns.dist_m
  LIMIT 1
),

/* 3. Daily precipitation (mm) for that station */
daily_prcp AS (
  SELECT
    date,
    SUM(value)/10.0 AS prcp_mm                       -- values are in 0.1 mm
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016` g
  JOIN station_choice sc
    ON g.id = sc.id
  WHERE g.element = 'PRCP'
    AND g.qflag IS NULL
  GROUP BY date
),

/* 4. Flag day as Rainy / Non-rainy */
rain_flag AS (
  SELECT
    date            AS trip_date,
    CASE WHEN prcp_mm > 5 THEN 'Rainy' ELSE 'Non-rainy' END AS day_type
  FROM daily_prcp
),

/* 5. Citi Bike trips per day in 2016 */
daily_citibike AS (
  SELECT
    DATE(starttime) AS trip_date,
    COUNT(*)        AS trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY trip_date
)

/* 6. Compare averages */
SELECT
  r.day_type,
  COUNT(*)                 AS num_days,
  ROUND(AVG(d.trips),1)    AS avg_daily_trips
FROM daily_citibike d
JOIN rain_flag r
  ON d.trip_date = r.trip_date
GROUP BY r.day_type
ORDER BY r.day_type;