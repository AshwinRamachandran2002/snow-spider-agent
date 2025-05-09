-- earliest time a trip leaves Clay & Drumm **and later reaches**
-- Sacramento & Davis (same trip, same direction), together with the
-- latest arrival at Sacramento & Davis for those trips, per route /
-- headsign.
WITH key_stops AS (   -- numeric stop_ids for the two stops
  SELECT
    MAX(CASE WHEN stop_name = 'Clay St & Drumm St'        THEN CAST(stop_id AS INT64) END) AS clay_id,
    MAX(CASE WHEN stop_name = 'Sacramento St & Davis St'  THEN CAST(stop_id AS INT64) END) AS sac_id
  FROM `bigquery-public-data.san_francisco_transit_muni.stops`
  WHERE stop_name IN ('Clay St & Drumm St','Sacramento St & Davis St')
),
paired_stops AS (     -- the two stops for the *same* trip
  SELECT
    tr.route_id,
    tr.trip_headsign,
    clay.departure_time   AS clay_depart,
    sac.arrival_time      AS sac_arrive
  FROM key_stops ks
  JOIN `bigquery-public-data.san_francisco_transit_muni.stop_times`  AS clay
       ON clay.stop_id = ks.clay_id
  JOIN `bigquery-public-data.san_francisco_transit_muni.stop_times`  AS sac
       ON sac.stop_id  = ks.sac_id
      AND sac.trip_id  = clay.trip_id                -- same trip
      AND clay.stop_sequence < sac.stop_sequence     -- Clay → Sacramento order
  JOIN `bigquery-public-data.san_francisco_transit_muni.trips`       AS tr
       ON tr.trip_id = CAST(clay.trip_id AS STRING)  -- bring in route / headsign
)
SELECT
  route_id,
  trip_headsign,
  FORMAT_TIME('%H:%M:%S', MIN(clay_depart))  AS earliest_depart_from_clay,
  FORMAT_TIME('%H:%M:%S', MAX(sac_arrive))   AS latest_arrive_at_sacramento
FROM paired_stops
GROUP BY route_id, trip_headsign
ORDER BY route_id, trip_headsign;