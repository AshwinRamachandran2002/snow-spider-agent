WITH latest_status AS (
  SELECT
    station_id,
    LOWER(status) AS status,
    ROW_NUMBER() OVER (PARTITION BY station_id ORDER BY modified_date DESC) AS rn
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`
),
station_status AS (
  SELECT
    station_id,
    status
  FROM latest_status
  WHERE rn = 1
),
trips_station_year AS (
  SELECT
    EXTRACT(YEAR FROM start_time) AS year,
    CAST(start_station_id AS INT64) AS station_id
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM start_time) IN (2013, 2014)
  
  UNION DISTINCT
  
  SELECT
    EXTRACT(YEAR FROM start_time) AS year,
    CAST(end_station_id AS INT64) AS station_id
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM start_time) IN (2013, 2014)
)
SELECT
  year,
  COUNT(DISTINCT IF(status = 'active', station_id, NULL)) AS active_stations,
  COUNT(DISTINCT IF(status = 'closed', station_id, NULL)) AS closed_stations
FROM trips_station_year
LEFT JOIN station_status USING (station_id)
GROUP BY year
ORDER BY year;