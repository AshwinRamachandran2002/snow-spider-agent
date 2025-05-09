-- Earliest departure at “Clay St & Drumm St” (stop_id = 14015)
-- and latest arrival at “Sacramento St & Davis St” (stop_id = 16294)
-- for all trips where Clay precedes Sacramento on the stop sequence.
SELECT
  tr.route_id,
  tr.trip_headsign,
  FORMAT_TIME('%H:%M:%S', MIN(TIME(st_clay.departure_time))) AS earliest_depart_from_clay,
  FORMAT_TIME('%H:%M:%S', MAX(TIME(st_sac.arrival_time)))    AS latest_arrive_at_sacramento
FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` AS st_clay
JOIN `bigquery-public-data.san_francisco_transit_muni.stop_times` AS st_sac
  ON st_clay.trip_id = st_sac.trip_id
JOIN `bigquery-public-data.san_francisco_transit_muni.trips`       AS tr
  ON tr.trip_id = CAST(st_clay.trip_id AS STRING)   -- align data types
WHERE st_clay.stop_id = 14015       -- Clay St & Drumm St
  AND st_sac.stop_id  = 16294       -- Sacramento St & Davis St
  AND st_clay.stop_sequence < st_sac.stop_sequence -- Clay occurs before Sacramento
GROUP BY tr.route_id, tr.trip_headsign
ORDER BY tr.route_id, tr.trip_headsign;