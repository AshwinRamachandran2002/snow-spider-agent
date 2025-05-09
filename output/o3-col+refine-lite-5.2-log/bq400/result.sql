-- Earliest departure from “Clay St & Drumm St” and latest arrival at
-- “Sacramento St & Davis St” for every (route_id, trip_headsign)
-- where the Clay stop appears BEFORE the Sacramento stop in the same trip.
WITH stop_codes AS (        -- numeric stop_id values for the two stops
  SELECT
    MAX(CASE WHEN stop_name = 'Clay St & Drumm St'
             THEN CAST(stop_id AS INT64) END) AS clay_id,
    MAX(CASE WHEN stop_name = 'Sacramento St & Davis St'
             THEN CAST(stop_id AS INT64) END) AS sac_id
  FROM `bigquery-public-data.san_francisco_transit_muni.stops`
  WHERE stop_name IN ('Clay St & Drumm St', 'Sacramento St & Davis St')
),
qualifying_trips AS (       -- trips where Clay precedes Sacramento
  SELECT DISTINCT CAST(c.trip_id AS STRING) AS trip_id
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` c
  JOIN `bigquery-public-data.san_francisco_transit_muni.stop_times` s
    ON c.trip_id = s.trip_id, stop_codes
  WHERE c.stop_id = stop_codes.clay_id
    AND s.stop_id = stop_codes.sac_id
    AND c.stop_sequence < s.stop_sequence
),
earliest_clay AS (
  SELECT
    t.route_id,
    t.trip_headsign,
    MIN(st.departure_time) AS clay_earliest     -- TIME (HH:MM:SS)
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` st
  JOIN qualifying_trips qt
    ON qt.trip_id = CAST(st.trip_id AS STRING)
  JOIN `bigquery-public-data.san_francisco_transit_muni.trips` t
    ON t.trip_id = qt.trip_id, stop_codes
  WHERE st.stop_id = stop_codes.clay_id
  GROUP BY t.route_id, t.trip_headsign
),
latest_sac AS (
  SELECT
    t.route_id,
    t.trip_headsign,
    MAX(st.arrival_time) AS sac_latest          -- TIME (HH:MM:SS)
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` st
  JOIN qualifying_trips qt
    ON qt.trip_id = CAST(st.trip_id AS STRING)
  JOIN `bigquery-public-data.san_francisco_transit_muni.trips` t
    ON t.trip_id = qt.trip_id, stop_codes
  WHERE st.stop_id = stop_codes.sac_id
  GROUP BY t.route_id, t.trip_headsign
)
SELECT
  e.route_id,
  e.trip_headsign,
  FORMAT_TIME('%H:%M:%S', e.clay_earliest) AS earliest_departure_clay,
  FORMAT_TIME('%H:%M:%S', l.sac_latest)    AS latest_arrival_sacramento
FROM earliest_clay e
JOIN latest_sac l USING (route_id, trip_headsign)
ORDER BY route_id, trip_headsign;