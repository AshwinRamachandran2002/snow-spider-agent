-- Earliest departure from 'Clay St & Drumm St' and latest arrival at
-- 'Sacramento St & Davis St' for the direction in which the first stop
-- precedes the second within the same trip.

WITH trip_stops AS (
  SELECT
    st.trip_id                       AS trip_id_int,
    tr.route_id,
    tr.trip_headsign,
    tr.direction,
    s.stop_name,
    st.stop_sequence,
    st.arrival_time,
    st.departure_time
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` st
  JOIN `bigquery-public-data.san_francisco_transit_muni.stops`  s
       ON s.stop_id = CAST(st.stop_id AS STRING)
  JOIN `bigquery-public-data.san_francisco_transit_muni.trips`  tr
       ON SAFE_CAST(tr.trip_id AS INT64) = st.trip_id
  WHERE s.stop_name IN ('Clay St & Drumm St', 'Sacramento St & Davis St')
),

trip_summary AS (
  SELECT
    trip_id_int,
    route_id,
    trip_headsign,
    direction,
    MIN(IF(stop_name = 'Clay St & Drumm St'     , stop_sequence, NULL)) AS clay_seq,
    MIN(IF(stop_name = 'Clay St & Drumm St'     , departure_time, NULL)) AS clay_departure,
    MIN(IF(stop_name = 'Sacramento St & Davis St', stop_sequence, NULL)) AS sac_seq,
    MAX(IF(stop_name = 'Sacramento St & Davis St', arrival_time  , NULL)) AS sac_arrival
  FROM trip_stops
  GROUP BY trip_id_int, route_id, trip_headsign, direction
),

qual_trips AS (
  -- keep only those trips where Clay precedes Sacramento
  SELECT *
  FROM trip_summary
  WHERE clay_seq IS NOT NULL
    AND sac_seq  IS NOT NULL
    AND clay_seq < sac_seq
)

SELECT
  route_id,
  trip_headsign,
  FORMAT_TIME('%H:%M:%S', MIN(clay_departure)) AS earliest_departure_clay,
  FORMAT_TIME('%H:%M:%S', MAX(sac_arrival))    AS latest_arrival_sac
FROM qual_trips
GROUP BY route_id, trip_headsign
ORDER BY route_id;