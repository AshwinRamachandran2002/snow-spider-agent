-- Task: Provide the number of distinct active bike share stations in 2013.
SELECT 
  COUNT(DISTINCT s.station_id) AS number_active_stations_2013
FROM 
  `bigquery-public-data.austin_bikeshare.bikeshare_trips` t
INNER JOIN 
  `bigquery-public-data.austin_bikeshare.bikeshare_stations` s
ON 
  t.start_station_id = s.station_id
WHERE 
  s.status = 'active' 
  AND EXTRACT(YEAR FROM t.start_time) = 2013;