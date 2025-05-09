-- Earliest departure from “Clay St & Drumm St” and
-- latest arrival at “Sacramento St & Davis St”
-- for the direction in which Clay precedes Sacramento,
-- reported per (route_id, trip_headsign)
WITH target_stops AS (
  SELECT
    CAST(stop_id AS INT64) AS stop_id_int,
    stop_name
  FROM `bigquery-public-data.san_francisco_transit_muni.stops`
  WHERE stop_name IN ('Clay St & Drumm St',
                      'Sacramento St & Davis St')
),
trip_stop_positions AS (
  SELECT
    st.trip_id,
    MAX(CASE WHEN ts.stop_name = 'Clay St & Drumm St'
             THEN st.stop_sequence END)        AS clay_seq,
    MAX(CASE WHEN ts.stop_name = 'Clay St & Drumm St'
             THEN st.departure_time END)       AS clay_depart,
    MAX(CASE WHEN ts.stop_name = 'Sacramento St & Davis St'
             THEN st.stop_sequence END)        AS sacr_seq,
    MAX(CASE WHEN ts.stop_name = 'Sacramento St & Davis St'
             THEN st.arrival_time END)         AS sacr_arrival
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` st
  JOIN target_stops ts
    ON st.stop_id = ts.stop_id_int
  GROUP BY st.trip_id
),
valid_trips AS (        -- keep only trips where Clay precedes Sacramento
  SELECT *
  FROM trip_stop_positions
  WHERE clay_seq IS NOT NULL
    AND sacr_seq IS NOT NULL
    AND clay_seq < sacr_seq               -- direction filter
),
trip_details AS (
  SELECT
    vt.trip_id,
    vt.clay_depart,
    vt.sacr_arrival,
    tr.route_id,
    tr.trip_headsign
  FROM valid_trips vt
  JOIN `bigquery-public-data.san_francisco_transit_muni.trips` tr
    ON CAST(tr.trip_id AS INT64) = vt.trip_id
)
SELECT
  route_id,
  trip_headsign,
  FORMAT_TIME('%H:%M:%S', MIN(clay_depart))  AS earliest_departure_from_clay,
  FORMAT_TIME('%H:%M:%S', MAX(sacr_arrival)) AS latest_arrival_at_sacramento
FROM trip_details
GROUP BY route_id, trip_headsign
ORDER BY route_id, trip_headsign;