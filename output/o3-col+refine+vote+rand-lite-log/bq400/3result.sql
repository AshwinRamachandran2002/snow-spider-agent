/*  Earliest departure from “Clay St & Drumm St” and latest arrival at 
    “Sacramento St & Davis St” for every route / head-sign in the direction
    where the Clay stop occurs before the Sacramento stop               */

WITH
-- rows for “Clay St & Drumm St”  (stop_id = 14015)
clay AS (
  SELECT
    CAST(trip_id AS INT64)           AS trip_id,
    stop_sequence                    AS clay_seq,
    departure_time                   AS clay_depart
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times`
  WHERE stop_id = 14015
),

-- rows for “Sacramento St & Davis St”  (stop_id = 16294)
sac AS (
  SELECT
    CAST(trip_id AS INT64)           AS trip_id,
    stop_sequence                    AS sac_seq,
    arrival_time                     AS sac_arrive
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times`
  WHERE stop_id = 16294
),

-- keep only those trips where the Clay stop precedes the Sacramento stop
paired AS (
  SELECT
    tr.route_id,
    tr.trip_headsign,
    c.clay_depart,
    s.sac_arrive
  FROM clay c
  JOIN sac  s USING (trip_id)
  JOIN `bigquery-public-data.san_francisco_transit_muni.trips` tr
        ON CAST(tr.trip_id AS INT64) = c.trip_id
  WHERE c.clay_seq < s.sac_seq               -- correct travel direction
)

SELECT
  route_id,
  trip_headsign,
  FORMAT_TIME('%H:%M:%S', MIN(clay_depart)) AS earliest_depart_clay,
  FORMAT_TIME('%H:%M:%S', MAX(sac_arrive))  AS latest_arrive_sacramento
FROM paired
GROUP BY route_id, trip_headsign
ORDER BY route_id, trip_headsign;