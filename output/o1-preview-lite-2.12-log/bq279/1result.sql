SELECT
  EXTRACT(YEAR FROM t.start_time) AS Year,
  COUNT(DISTINCT CASE WHEN LOWER(s.status) = 'active' THEN t.start_station_id END) AS Number_of_Stations_active,
  COUNT(DISTINCT CASE WHEN LOWER(s.status) = 'closed' THEN t.start_station_id END) AS Number_of_Stations_closed
FROM
  `bigquery-public-data.austin_bikeshare.bikeshare_trips` AS t
JOIN
  `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS s
ON
  t.start_station_id = s.station_id
WHERE
  EXTRACT(YEAR FROM t.start_time) IN (2013, 2014)
GROUP BY
  Year
ORDER BY
  Year;