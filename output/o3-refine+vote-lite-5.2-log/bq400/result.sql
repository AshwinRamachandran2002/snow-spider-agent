/*  Earliest departure from “Clay St & Drumm St” and
    latest arrival at “Sacramento St & Davis St”
    (consider only trips where the Clay stop occurs before the Sacramento stop) */

WITH
-- stop_ids for the two stops (stop_ids are STRING in `stops`)
clay_stop AS (
  SELECT stop_id
  FROM `bigquery-public-data.san_francisco_transit_muni.stops`
  WHERE stop_name = 'Clay St & Drumm St'
),
sac_stop AS (
  SELECT stop_id
  FROM `bigquery-public-data.san_francisco_transit_muni.stops`
  WHERE stop_name = 'Sacramento St & Davis St'
),

-- stop‑times for Clay
clay_times AS (
  SELECT
    CAST(st.trip_id AS STRING)        AS trip_id,      -- make it STRING to match `trips`
    st.departure_time                 AS clay_depart,
    st.stop_sequence                  AS clay_seq
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` st
  JOIN clay_stop cs
    ON CAST(st.stop_id AS STRING) = cs.stop_id         -- stop_id types aligned
),

-- stop‑times for Sacramento
sac_times AS (
  SELECT
    CAST(st.trip_id AS STRING)        AS trip_id,
    st.arrival_time                   AS sac_arrive,
    st.stop_sequence                  AS sac_seq
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` st
  JOIN sac_stop ss
    ON CAST(st.stop_id AS STRING) = ss.stop_id
),

-- trips where Clay comes before Sacramento
valid_trips AS (
  SELECT
    c.trip_id,
    c.clay_depart,
    s.sac_arrive
  FROM clay_times c
  JOIN sac_times s
    ON c.trip_id = s.trip_id
  WHERE c.clay_seq < s.sac_seq
)

SELECT
  tr.route_id,
  tr.trip_headsign,
  MIN(vt.clay_depart) AS earliest_departure,   -- HH:MM:SS
  MAX(vt.sac_arrive)  AS latest_arrival        -- HH:MM:SS
FROM valid_trips vt
JOIN `bigquery-public-data.san_francisco_transit_muni.trips` tr
  ON tr.trip_id = vt.trip_id
GROUP BY
  tr.route_id,
  tr.trip_headsign
ORDER BY
  tr.route_id,
  tr.trip_headsign;