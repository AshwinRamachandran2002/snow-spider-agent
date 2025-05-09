-- Earliest departure from “Clay St & Drumm St” (stop_id 14015) and
-- latest arrival at “Sacramento St & Davis St” (stop_id 16294)
-- for trips where Clay appears before Sacramento in the stop sequence.
WITH
  clay AS (
    SELECT
      CAST(trip_id AS STRING) AS trip_id,
      departure_time           AS clay_depart,
      stop_sequence
    FROM `bigquery-public-data.san_francisco_transit_muni.stop_times`
    WHERE stop_id = 14015                         -- Clay St & Drumm St
  ),
  sacr AS (
    SELECT
      CAST(trip_id AS STRING) AS trip_id,
      arrival_time            AS sacr_arrive,
      stop_sequence
    FROM `bigquery-public-data.san_francisco_transit_muni.stop_times`
    WHERE stop_id = 16294                         -- Sacramento St & Davis St
  )
SELECT
  tr.route_id,
  tr.trip_headsign,
  FORMAT_TIME('%H:%M:%S', MIN(clay.clay_depart)) AS earliest_from_clay,
  FORMAT_TIME('%H:%M:%S', MAX(sacr.sacr_arrive)) AS latest_at_sacramento
FROM `bigquery-public-data.san_francisco_transit_muni.trips` AS tr
JOIN clay ON tr.trip_id = clay.trip_id
JOIN sacr ON tr.trip_id = sacr.trip_id
WHERE clay.stop_sequence < sacr.stop_sequence     -- ensure correct travel direction
GROUP BY tr.route_id, tr.trip_headsign
ORDER BY tr.route_id, tr.trip_headsign;