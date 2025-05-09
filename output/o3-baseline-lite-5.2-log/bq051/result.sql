-- Average 2016 Citi Bike daily trips on rainy (>5 mm) vs. non‑rainy days
WITH nearby_stations AS (
  SELECT
    s.id,
    ST_DISTANCE(
      ST_GEOGPOINT(s.longitude, s.latitude),
      ST_GEOGPOINT(-74.0060, 40.7128)        -- NYC (Times Sq.) reference point
    ) AS distance_m
  FROM `bigquery-public-data.ghcn_d.ghcnd_stations` AS s
  WHERE ST_DISTANCE(
          ST_GEOGPOINT(s.longitude, s.latitude),
          ST_GEOGPOINT(-74.0060, 40.7128)
        ) <= 50000                           -- within 50 km
),
station_with_prcp AS (
  SELECT ns.id, ns.distance_m
  FROM nearby_stations AS ns
  JOIN (
    SELECT DISTINCT id
    FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
    WHERE element = 'PRCP'               -- precipitation
      AND qflag IS NULL                  -- keep only un‑flagged rows
  ) AS w
  ON ns.id = w.id
),
chosen_station AS (
  SELECT id
  FROM station_with_prcp
  ORDER BY distance_m                    -- closest valid station
  LIMIT 1
),
weather AS (
  SELECT
    date,
    SUM(value) / 10.0 AS prcp_mm         -- convert 1/10 mm units → mm
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
  WHERE element = 'PRCP'
    AND qflag IS NULL
    AND id IN (SELECT id FROM chosen_station)
  GROUP BY date
),
weather_flag AS (
  SELECT
    date,
    CASE WHEN prcp_mm > 5 THEN 'rainy' ELSE 'non_rainy' END AS rain_flag
  FROM weather
),
daily_trips AS (
  SELECT
    DATE(starttime) AS date,
    COUNT(*)       AS trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY date
),
combined AS (
  SELECT w.rain_flag, t.trips
  FROM weather_flag AS w
  JOIN daily_trips AS t
  USING (date)                           -- keep only days with both data sources
)
SELECT
  rain_flag,
  ROUND(AVG(trips), 2) AS avg_daily_trips
FROM combined
GROUP BY rain_flag
ORDER BY rain_flag;