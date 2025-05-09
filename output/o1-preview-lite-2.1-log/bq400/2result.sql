SELECT
  st1.departure_time AS Start_Time,
  st2.arrival_time AS End_Time,
  t.trip_headsign AS Trip_Headsign
FROM
  `bigquery-public-data.san_francisco_transit_muni.stop_times` AS st1
JOIN
  `bigquery-public-data.san_francisco_transit_muni.stop_times` AS st2
  ON st1.trip_id = st2.trip_id
JOIN
  `bigquery-public-data.san_francisco_transit_muni.stops` AS s1
  ON CAST(st1.stop_id AS STRING) = s1.stop_id
JOIN
  `bigquery-public-data.san_francisco_transit_muni.stops` AS s2
  ON CAST(st2.stop_id AS STRING) = s2.stop_id
JOIN
  `bigquery-public-data.san_francisco_transit_muni.trips` AS t
  ON CAST(st1.trip_id AS STRING) = t.trip_id
WHERE
  s1.stop_name = 'Clay St & Drumm St'
  AND s2.stop_name = 'Sacramento St & Davis St'
  AND st1.stop_sequence < st2.stop_sequence
  AND t.direction = 'I'
ORDER BY
  st1.departure_time;