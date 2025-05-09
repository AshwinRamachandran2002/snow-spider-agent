SELECT
  st1.departure_time AS Start_Time,
  st2.arrival_time AS End_Time,
  t.trip_headsign AS Trip_Headsign
FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` AS st1
JOIN `bigquery-public-data.san_francisco_transit_muni.stop_times` AS st2
  ON st1.trip_id = st2.trip_id
JOIN `bigquery-public-data.san_francisco_transit_muni.trips` AS t
  ON CAST(st1.trip_id AS STRING) = t.trip_id
WHERE CAST(st1.stop_id AS STRING) IN (
  SELECT stop_id
  FROM `bigquery-public-data.san_francisco_transit_muni.stops`
  WHERE LOWER(stop_name) = LOWER('Clay St & Drumm St')
)
AND CAST(st2.stop_id AS STRING) IN (
  SELECT stop_id
  FROM `bigquery-public-data.san_francisco_transit_muni.stops`
  WHERE LOWER(stop_name) = LOWER('Sacramento St & Davis St')
)
AND st1.stop_sequence < st2.stop_sequence
ORDER BY st1.departure_time;