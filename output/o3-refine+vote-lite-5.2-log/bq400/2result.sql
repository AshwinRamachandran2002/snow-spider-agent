/*  Earliest departure from 'Clay St & Drumm St' and latest arrival at
    'Sacramento St & Davis St' by route / head‑sign, only for trips where
    the Clay stop occurs earlier in the stop sequence than the Sacramento stop.
*/
WITH
-- stop_ids of the two stops, cast to INT64 to match stop_times.stop_id
clay AS (
  SELECT CAST(stop_id AS INT64) AS stop_id
  FROM `bigquery-public-data.san_francisco_transit_muni.stops`
  WHERE stop_name = 'Clay St & Drumm St'
),
sac AS (
  SELECT CAST(stop_id AS INT64) AS stop_id
  FROM `bigquery-public-data.san_francisco_transit_muni.stops`
  WHERE stop_name = 'Sacramento St & Davis St'
),

-- pair the two stops on every trip where Clay precedes Sacramento
trip_pairs AS (
  SELECT
    st_clay.trip_id,
    st_clay.departure_time AS clay_depart_time,
    st_sac.arrival_time    AS sac_arrive_time
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` AS st_clay
  JOIN clay c  ON st_clay.stop_id = c.stop_id                              -- Clay stop
  JOIN `bigquery-public-data.san_francisco_transit_muni.stop_times` AS st_sac
       ON st_clay.trip_id = st_sac.trip_id
  JOIN sac  s  ON st_sac.stop_id = s.stop_id                               -- Sacramento stop
  WHERE st_clay.stop_sequence < st_sac.stop_sequence                       -- Clay occurs first
),

-- enrich with route and head‑sign (cast trip_id to STRING for the join)
trip_info AS (
  SELECT
    tp.trip_id,
    tp.clay_depart_time,
    tp.sac_arrive_time,
    tr.route_id,
    tr.trip_headsign
  FROM trip_pairs AS tp
  JOIN `bigquery-public-data.san_francisco_transit_muni.trips` AS tr
    ON tr.trip_id = CAST(tp.trip_id AS STRING)
)

-- final aggregation
SELECT
  route_id,
  trip_headsign,
  FORMAT_TIME('%H:%M:%S', MIN(clay_depart_time)) AS earliest_departure_from_clay,
  FORMAT_TIME('%H:%M:%S', MAX(sac_arrive_time))  AS latest_arrival_at_sacramento
FROM trip_info
GROUP BY route_id, trip_headsign
ORDER BY route_id, trip_headsign;