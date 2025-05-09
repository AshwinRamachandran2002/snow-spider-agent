WITH
-- stop_ids for the two stops of interest
stops_interest AS (
  SELECT
    CAST(stop_id AS INT64) AS stop_id,
    stop_name
  FROM `bigquery-public-data.san_francisco_transit_muni.stops`
  WHERE stop_name IN ('Clay St & Drumm St','Sacramento St & Davis St')
),

-- stop_times rows for each of those stops
clay AS (
  SELECT
    CAST(st.trip_id AS STRING)            AS trip_id,
    st.stop_sequence,
    st.departure_time                     AS clay_departure_time
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` st
  JOIN stops_interest si
    ON st.stop_id = si.stop_id
  WHERE si.stop_name = 'Clay St & Drumm St'
),
sac AS (
  SELECT
    CAST(st.trip_id AS STRING)            AS trip_id,
    st.stop_sequence,
    st.arrival_time                       AS sac_arrival_time
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` st
  JOIN stops_interest si
    ON st.stop_id = si.stop_id
  WHERE si.stop_name = 'Sacramento St & Davis St'
),

-- keep only trips where Clay precedes Sacramento
qualified_trips AS (
  SELECT
    c.trip_id,
    c.clay_departure_time,
    s.sac_arrival_time
  FROM clay c
  JOIN sac  s
    ON c.trip_id = s.trip_id
  WHERE c.stop_sequence < s.stop_sequence     -- Clay occurs before Sacramento
),

-- add route and headsign information
trip_details AS (
  SELECT
    qt.trip_id,
    t.route_id,
    t.trip_headsign,
    qt.clay_departure_time,
    qt.sac_arrival_time
  FROM qualified_trips qt
  JOIN `bigquery-public-data.san_francisco_transit_muni.trips` t
    ON qt.trip_id = t.trip_id
)

-- final aggregation per route / headsign
SELECT
  route_id,
  trip_headsign,
  FORMAT_TIME('%H:%M:%S', MIN(clay_departure_time)) AS earliest_clay_departure,
  FORMAT_TIME('%H:%M:%S', MAX(sac_arrival_time))    AS latest_sac_arrival
FROM trip_details
GROUP BY
  route_id,
  trip_headsign
ORDER BY
  route_id;