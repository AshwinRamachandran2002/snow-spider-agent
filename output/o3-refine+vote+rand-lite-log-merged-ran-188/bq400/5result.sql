WITH target_stops AS (
  -- get the stop_ids for the two stop names we care about
  SELECT
    CASE
      WHEN stop_name = 'Clay St & Drumm St'        THEN 'clay'
      WHEN stop_name = 'Sacramento St & Davis St'  THEN 'sac'
    END                                                   AS stop_tag,
    CAST(stop_id AS INT64)                                AS stop_id
  FROM `bigquery-public-data.san_francisco_transit_muni.stops`
  WHERE stop_name IN ('Clay St & Drumm St','Sacramento St & Davis St')
),
trip_level AS (
  /*  Collect, for every trip that serves BOTH stops, the
      sequence positions and the times at the two stops          */
  SELECT
    st.trip_id,
    MIN(CASE WHEN st.stop_id IN (SELECT stop_id FROM target_stops WHERE stop_tag='clay')
             THEN st.stop_sequence END)                        AS clay_seq,
    MIN(CASE WHEN st.stop_id IN (SELECT stop_id FROM target_stops WHERE stop_tag='sac')
             THEN st.stop_sequence END)                        AS sac_seq,
    MIN(CASE WHEN st.stop_id IN (SELECT stop_id FROM target_stops WHERE stop_tag='clay')
             THEN st.departure_time END)                       AS clay_departure_time,
    MAX(CASE WHEN st.stop_id IN (SELECT stop_id FROM target_stops WHERE stop_tag='sac')
             THEN st.arrival_time END)                         AS sac_arrival_time
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` AS st
  WHERE st.stop_id IN (SELECT stop_id FROM target_stops)
  GROUP BY st.trip_id
),
qualified_trips AS (
  /* keep only trips where Clay precedes Sacramento */
  SELECT
    tl.trip_id,
    tl.clay_departure_time,
    tl.sac_arrival_time,
    tr.route_id,
    tr.trip_headsign
  FROM trip_level tl
  JOIN `bigquery-public-data.san_francisco_transit_muni.trips`  tr
        ON tr.trip_id = CAST(tl.trip_id AS STRING)
  WHERE tl.clay_seq IS NOT NULL
    AND tl.sac_seq  IS NOT NULL
    AND tl.clay_seq < tl.sac_seq          -- Clay comes before Sacramento
)
SELECT
  route_id,
  trip_headsign,
  FORMAT_TIME('%T', MIN(clay_departure_time)) AS earliest_departure_time,
  FORMAT_TIME('%T', MAX(sac_arrival_time))    AS latest_arrival_time
FROM qualified_trips
GROUP BY route_id, trip_headsign
ORDER BY route_id, trip_headsign;