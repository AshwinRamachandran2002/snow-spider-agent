WITH nyc AS (
  SELECT ST_GEOGPOINT(-74.0060, 40.7128) AS geom
),
nearby_stations AS (
  SELECT
    s.id,
    ST_DISTANCE(ST_GEOGPOINT(s.longitude, s.latitude),
                (SELECT geom FROM nyc)) AS distance_m
  FROM `bigquery-public-data.ghcn_d.ghcnd_stations` AS s
  WHERE s.longitude IS NOT NULL
    AND s.latitude  IS NOT NULL
    AND ST_DISTANCE(ST_GEOGPOINT(s.longitude, s.latitude),
                    (SELECT geom FROM nyc)) <= 50000
),
station_quality AS (
  SELECT
    id,
    COUNTIF(element = 'PRCP' AND qflag IS NULL) AS valid_prcp_rows
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
  GROUP BY id
),
best_station AS (
  SELECT n.id
  FROM nearby_stations n
  JOIN station_quality q USING (id)
  ORDER BY q.valid_prcp_rows DESC, n.distance_m ASC
  LIMIT 1
),
daily_precip AS (
  SELECT
    date,
    SUM(value) / 10.0 AS prcp_mm
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
  WHERE id IN (SELECT id FROM best_station)
    AND element = 'PRCP'
    AND qflag IS NULL
  GROUP BY date
),
precip_flag AS (
  SELECT
    date,
    CASE WHEN prcp_mm > 5.0 THEN 'rainy' ELSE 'non_rainy' END AS rain_category
  FROM daily_precip
),
bike_daily AS (
  SELECT
    DATE(starttime) AS ride_day,
    COUNT(*)        AS trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY ride_day
),
combined AS (
  SELECT
    b.ride_day,
    COALESCE(p.rain_category, 'non_rainy') AS rain_category,
    b.trips
  FROM bike_daily b
  LEFT JOIN precip_flag p
    ON b.ride_day = p.date
)
SELECT
  rain_category,
  ROUND(AVG(trips), 4) AS average_daily_citibike_trips_2016
FROM combined
GROUP BY rain_category
ORDER BY rain_category;