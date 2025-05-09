/*  Earliest departure from “Clay St & Drumm St” and latest arrival at
    “Sacramento St & Davis St” for every (route_id , trip_headsign)
    where the bus/train stops at Clay *before* Sacramento on the same trip.
*/
WITH stop_ids AS (            -- find the exact numeric stop_id’s once
  SELECT
    MAX(CASE WHEN LOWER(stop_name) = 'clay st & drumm st'
             THEN CAST(stop_id AS INT64) END) AS clay_id,
    MAX(CASE WHEN LOWER(stop_name) = 'sacramento st & davis st'
             THEN CAST(stop_id AS INT64) END) AS sac_id
  FROM `bigquery-public-data.san_francisco_transit_muni.stops`
),
qualified_trips AS (          -- trips where Clay precedes Sacramento
  SELECT DISTINCT CAST(clay.trip_id AS STRING) AS trip_id
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` AS clay
  JOIN `bigquery-public-data.san_francisco_transit_muni.stop_times` AS sac
    ON clay.trip_id = sac.trip_id
  CROSS JOIN stop_ids
  WHERE clay.stop_id = stop_ids.clay_id
    AND sac.stop_id  = stop_ids.sac_id
    AND clay.stop_sequence < sac.stop_sequence
),
clay_times AS (                -- earliest departure from Clay per route/headsign
  SELECT
    tr.route_id,
    tr.trip_headsign,
    MIN(clay.departure_time) AS earliest_depart
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` AS clay
  JOIN qualified_trips                 q ON CAST(clay.trip_id AS STRING) = q.trip_id
  JOIN `bigquery-public-data.san_francisco_transit_muni.trips`       tr ON tr.trip_id = q.trip_id
  CROSS JOIN stop_ids
  WHERE clay.stop_id = stop_ids.clay_id
  GROUP BY tr.route_id, tr.trip_headsign
),
sac_times AS (                 -- latest arrival at Sacramento per route/headsign
  SELECT
    tr.route_id,
    tr.trip_headsign,
    MAX(sac.arrival_time) AS latest_arrival
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` AS sac
  JOIN qualified_trips                 q ON CAST(sac.trip_id AS STRING) = q.trip_id
  JOIN `bigquery-public-data.san_francisco_transit_muni.trips`       tr ON tr.trip_id = q.trip_id
  CROSS JOIN stop_ids
  WHERE sac.stop_id = stop_ids.sac_id
  GROUP BY tr.route_id, tr.trip_headsign
)
SELECT
  c.route_id,
  c.trip_headsign,
  FORMAT_TIME('%T', c.earliest_depart) AS earliest_depart_from_clay,
  FORMAT_TIME('%T', s.latest_arrival)  AS latest_arrival_at_sacramento
FROM clay_times AS c
JOIN sac_times  AS s
  ON c.route_id       = s.route_id
 AND c.trip_headsign  = s.trip_headsign
ORDER BY c.route_id, c.trip_headsign;