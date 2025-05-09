SELECT
  r.name AS Region_Name,
  t.trip_id AS Trip_ID,
  t.duration_sec AS Ride_Duration,
  t.start_date AS Start_Time,
  s.name AS Starting_Station,
  t.member_gender AS Gender_of_Rider
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS t
JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
  ON t.start_station_id = CAST(s.station_id AS INT64)
JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` AS r
  ON s.region_id = r.region_id
WHERE t.start_date BETWEEN '2014-01-01' AND '2017-12-31'
QUALIFY ROW_NUMBER() OVER (PARTITION BY r.region_id ORDER BY t.start_date DESC) = 1;