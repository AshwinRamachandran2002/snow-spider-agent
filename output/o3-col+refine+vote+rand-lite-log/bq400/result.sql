-- Earliest departure from “Clay St & Drumm St” and latest arrival at
-- “Sacramento St & Davis St”, for the direction where Clay precedes Sacramento.
-- Results are per route / trip-headsign and times are shown as HH:MM:SS.
WITH
  clay_stop  AS (SELECT 14015 AS stop_id),      -- Clay St & Drumm St
  sac_stop   AS (SELECT 16294 AS stop_id)       -- Sacramento St & Davis St
SELECT
  r.route_short_name                 AS route,
  t.trip_headsign,
  FORMAT_TIME('%H:%M:%S',
              MIN(c.departure_time)) AS earliest_depart_clay,
  FORMAT_TIME('%H:%M:%S',
              MAX(s.arrival_time))   AS latest_arrive_sac
FROM  `bigquery-public-data.san_francisco_transit_muni.stop_times` AS c
JOIN  `bigquery-public-data.san_francisco_transit_muni.stop_times` AS s
      ON  c.trip_id = s.trip_id
JOIN  `bigquery-public-data.san_francisco_transit_muni.trips`  AS t
      ON  t.trip_id = CAST(c.trip_id AS STRING)          -- align INT64 ↔ STRING
JOIN  `bigquery-public-data.san_francisco_transit_muni.routes` AS r
      ON  r.route_id = t.route_id
WHERE c.stop_id = (SELECT stop_id FROM clay_stop)
  AND s.stop_id = (SELECT stop_id FROM sac_stop)
  AND c.stop_sequence < s.stop_sequence                   -- Clay before Sacramento
GROUP BY
  r.route_short_name,
  t.trip_headsign
ORDER BY
  route;