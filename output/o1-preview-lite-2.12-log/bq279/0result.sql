SELECT
  year,
  COUNT(DISTINCT CASE WHEN s.status = 'active' THEN s.station_id ELSE NULL END) AS Number_of_Stations_active,
  COUNT(DISTINCT CASE WHEN s.status = 'closed' THEN s.station_id ELSE NULL END) AS Number_of_Stations_closed
FROM (
  SELECT DISTINCT EXTRACT(YEAR FROM start_time) AS year, start_station_id AS station_id
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM start_time) IN (2013, 2014)
  UNION ALL
  SELECT DISTINCT EXTRACT(YEAR FROM start_time) AS year, CAST(end_station_id AS INT64) AS station_id
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM start_time) IN (2013, 2014)
) AS station_years
JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS s
ON station_years.station_id = s.station_id
GROUP BY year
ORDER BY year;