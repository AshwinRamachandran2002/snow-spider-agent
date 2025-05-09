SELECT
  year,
  COUNT(DISTINCT station_id) AS Number_of_Stations_active,
  (SELECT COUNT(DISTINCT station_id) FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`) - COUNT(DISTINCT station_id) AS Number_of_Stations_closed
FROM (
  SELECT
    EXTRACT(YEAR FROM start_time) AS year,
    start_station_id AS station_id
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM start_time) IN (2013, 2014)
)
GROUP BY year
ORDER BY year;