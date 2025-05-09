SELECT
  FORMAT_TIME('%H:%M:%S', a.arrival_time) AS Start_Time,
  FORMAT_TIME('%H:%M:%S', b.arrival_time) AS End_Time,
  t.trip_headsign AS Trip_Headsign
FROM
  `bigquery-public-data.san_francisco_transit_muni.stop_times` AS a
JOIN
  `bigquery-public-data.san_francisco_transit_muni.stop_times` AS b
    ON a.trip_id = b.trip_id
JOIN
  `bigquery-public-data.san_francisco_transit_muni.trips` AS t
    ON a.trip_id = CAST(t.trip_id AS INT64)
JOIN
  `bigquery-public-data.san_francisco_transit_muni.stops` AS s1
    ON a.stop_id = CAST(s1.stop_id AS INT64)
JOIN
  `bigquery-public-data.san_francisco_transit_muni.stops` AS s2
    ON b.stop_id = CAST(s2.stop_id AS INT64)
WHERE
  s1.stop_name = 'Clay St & Drumm St'
  AND s2.stop_name = 'Sacramento St & Davis St'
  AND a.stop_sequence < b.stop_sequence
ORDER BY a.arrival_time;