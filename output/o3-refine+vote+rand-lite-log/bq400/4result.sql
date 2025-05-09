-- Earliest departure from “Clay St & Drumm St” and latest arrival at
-- “Sacramento St & Davis St”, considering only trips where Clay is
-- served before Sacramento (one direction).
WITH
-- 1.  stop_id lists -----------------------------------------------------------
clay AS (
  SELECT DISTINCT CAST(stop_id AS INT64) AS stop_id
  FROM `bigquery-public-data.san_francisco_transit_muni.stops`
  WHERE stop_name = 'Clay St & Drumm St'
),
sac AS (
  SELECT DISTINCT CAST(stop_id AS INT64) AS stop_id
  FROM `bigquery-public-data.san_francisco_transit_muni.stops`
  WHERE stop_name = 'Sacramento St & Davis St'
),

-- 2. trips where Clay appears before Sacramento ------------------------------
trip_dir AS (
  SELECT
    CAST(st.trip_id AS STRING) AS trip_id,                   -- cast to STRING for later JOIN
    MAX(IF(st.stop_id IN (SELECT stop_id FROM clay), st.stop_sequence, NULL)) AS clay_seq,
    MAX(IF(st.stop_id IN (SELECT stop_id FROM sac),  st.stop_sequence, NULL)) AS sac_seq
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` st
  WHERE st.stop_id IN (SELECT stop_id FROM clay)
     OR st.stop_id IN (SELECT stop_id FROM sac)
  GROUP BY st.trip_id
  HAVING clay_seq IS NOT NULL
     AND sac_seq  IS NOT NULL
     AND clay_seq < sac_seq                                   -- Clay precedes Sacramento
),

-- 3. pull times for the qualifying trips -------------------------------------
times AS (
  SELECT
    tr.route_id,
    tr.trip_headsign,
    CASE
      WHEN st.stop_id IN (SELECT stop_id FROM clay) THEN st.departure_time
    END AS clay_dep_time,
    CASE
      WHEN st.stop_id IN (SELECT stop_id FROM sac) THEN st.arrival_time
    END AS sac_arr_time
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` st
  JOIN trip_dir td
        ON CAST(st.trip_id AS STRING) = td.trip_id
  JOIN `bigquery-public-data.san_francisco_transit_muni.trips` tr
        ON tr.trip_id = td.trip_id
)

-- 4. compute earliest / latest per route -------------------------------------
SELECT
  route_id,
  ANY_VALUE(trip_headsign)                          AS trip_headsign,
  FORMAT_TIME('%T', MIN(clay_dep_time))             AS earliest_departure_from_clay,
  FORMAT_TIME('%T', MAX(sac_arr_time))              AS latest_arrival_at_sacramento
FROM times
GROUP BY route_id
ORDER BY route_id;