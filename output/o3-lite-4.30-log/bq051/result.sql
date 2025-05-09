WITH nyc AS (
  SELECT ST_GEOGPOINT(-74.0060, 40.7128) AS geom
),

-- nearest GHCN station (≤50 km) that has at least one valid 2016 PRCP record
nearest_station AS (
  SELECT id
  FROM (
    SELECT
      s.id,
      ST_DISTANCE(ST_GEOGPOINT(s.longitude, s.latitude), (SELECT geom FROM nyc)) AS dist_m
    FROM `bigquery-public-data.ghcn_d.ghcnd_stations` AS s
    JOIN `bigquery-public-data.ghcn_d.ghcnd_2016`        AS d
      ON d.id = s.id
     AND d.element = 'PRCP'
     AND d.qflag  IS NULL
    WHERE s.longitude IS NOT NULL
      AND s.latitude  IS NOT NULL
      AND ST_DISTANCE(ST_GEOGPOINT(s.longitude, s.latitude), (SELECT geom FROM nyc)) < 50000
    GROUP BY s.id, dist_m
    ORDER BY dist_m
    LIMIT 1
  )
),

-- daily precipitation (mm) at that station
daily_precip AS (
  SELECT
    DATE(date)        AS obs_date,
    SUM(value) / 10.0 AS prcp_mm      -- raw values are in 0.1 mm
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
  WHERE id     IN (SELECT id FROM nearest_station)
    AND element = 'PRCP'
    AND qflag  IS NULL
  GROUP BY obs_date
),

-- daily Citi Bike trip counts for 2016
daily_trips AS (
  SELECT
    DATE(starttime) AS ride_date,
    COUNT(*)        AS trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY ride_date
)

-- average trips on rainy (>5 mm) vs non‑rainy days
SELECT
  CASE WHEN IFNULL(prcp_mm, 0) > 5 THEN 'Rainy' ELSE 'Non‑rainy' END AS rain_category,
  ROUND(AVG(trips), 4) AS average_daily_citibike_trips_2016
FROM daily_trips
LEFT JOIN daily_precip
       ON ride_date = obs_date
GROUP BY rain_category
ORDER BY rain_category;