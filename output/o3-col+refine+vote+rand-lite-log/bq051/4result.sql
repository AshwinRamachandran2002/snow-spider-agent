-- Average daily Citi Bike trips in 2016 on Rainy vs. Non-rainy days
-- (Rainy = > 5 mm precipitation) using the nearest GHCN station ≤ 50 km
-- from NYC that has valid, un-flagged precipitation data.

WITH nyc AS (
  SELECT ST_GEOGPOINT(-74.0060 , 40.7128) AS pt           -- NYC coordinates
),

/* 1.  Nearest GHCN station within 50 km of NYC */
nearest_station AS (
  SELECT
    id,
    name,
    ST_DISTANCE(ST_GEOGPOINT(longitude, latitude), (SELECT pt FROM nyc)) AS dist_m
  FROM `bigquery-public-data.ghcn_d.ghcnd_stations`
  WHERE ST_DISTANCE(ST_GEOGPOINT(longitude, latitude), (SELECT pt FROM nyc)) <= 50000
  ORDER BY dist_m
  LIMIT 1
),

/* 2.  Daily precipitation (mm) for that station in 2016, quality-flag-free */
precip AS (
  SELECT
    g.date,
    g.value / 10.0 AS precip_mm                         -- convert 0.1 mm → mm
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016` AS g
  JOIN nearest_station ns
        ON g.id = ns.id
  WHERE g.element = 'PRCP'
    AND g.qflag  IS NULL
),

/* 3.  Citi Bike trips per calendar day in 2016 */
trips_per_day AS (
  SELECT
    DATE(starttime) AS trip_date,
    COUNT(*)        AS trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY trip_date
)

/* 4.  Join, classify each day, and compute averages */
SELECT
  CASE WHEN IFNULL(p.precip_mm, 0) > 5 THEN 'Rainy' ELSE 'Non-rainy' END AS rain_flag,
  AVG(t.trips) AS avg_daily_trips
FROM trips_per_day t
LEFT JOIN precip p
       ON p.date = t.trip_date
GROUP BY rain_flag
ORDER BY rain_flag;