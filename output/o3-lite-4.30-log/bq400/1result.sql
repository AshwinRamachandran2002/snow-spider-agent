WITH clay AS (
  SELECT
    st.trip_id,
    st.stop_sequence,
    st.departure_time AS clay_depart
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` AS st
  JOIN `bigquery-public-data.san_francisco_transit_muni.stops` AS s
    ON st.stop_id = CAST(s.stop_id AS INT64)
  WHERE s.stop_name = 'Clay St & Drumm St'
),
sacramento AS (
  SELECT
    st.trip_id,
    st.stop_sequence,
    st.arrival_time AS sac_arrive
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` AS st
  JOIN `bigquery-public-data.san_francisco_transit_muni.stops` AS s
    ON st.stop_id = CAST(s.stop_id AS INT64)
  WHERE s.stop_name = 'Sacramento St & Davis St'
),
qualified AS (
  SELECT
    c.trip_id,
    c.clay_depart,
    s.sac_arrive
  FROM clay c
  JOIN sacramento s USING (trip_id)
  WHERE c.stop_sequence < s.stop_sequence
)
SELECT
  tr.trip_headsign,
  FORMAT_TIME('%H:%M:%S', MIN(q.clay_depart)) AS earliest_departure_time,
  FORMAT_TIME('%H:%M:%S', MAX(q.sac_arrive))  AS latest_arrival_time
FROM qualified q
JOIN `bigquery-public-data.san_francisco_transit_muni.trips` tr
  ON CAST(q.trip_id AS STRING) = tr.trip_id
WHERE tr.direction = 'I'  -- one direction only
GROUP BY tr.trip_headsign
ORDER BY tr.trip_headsign;