WITH stop_ids AS (
  SELECT stop_name, stop_id
  FROM `bigquery-public-data.san_francisco_transit_muni.stops`
  WHERE stop_name IN ('Clay St & Drumm St', 'Sacramento St & Davis St')
),
trip_times AS (
  SELECT
    st.trip_id,
    MAX(CASE WHEN s.stop_name = 'Clay St & Drumm St'
             THEN st.departure_time END)            AS dep_clay,
    MAX(CASE WHEN s.stop_name = 'Clay St & Drumm St'
             THEN st.stop_sequence END)             AS seq_clay,
    MAX(CASE WHEN s.stop_name = 'Sacramento St & Davis St'
             THEN st.arrival_time END)              AS arr_sac,
    MAX(CASE WHEN s.stop_name = 'Sacramento St & Davis St'
             THEN st.stop_sequence END)             AS seq_sac
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` AS st
  JOIN stop_ids AS s
    ON CAST(st.stop_id AS STRING) = s.stop_id
  GROUP BY st.trip_id
  HAVING seq_clay IS NOT NULL
     AND seq_sac  IS NOT NULL
     AND seq_clay < seq_sac                       -- Clay occurs before Sacramento
),
trips_with_info AS (
  SELECT
    tr.trip_headsign,
    tt.dep_clay,
    tt.arr_sac
  FROM trip_times AS tt
  JOIN `bigquery-public-data.san_francisco_transit_muni.trips` AS tr
    ON tr.trip_id = CAST(tt.trip_id AS STRING)
)
SELECT
  trip_headsign,
  FORMAT_TIME('%H:%M:%S', MIN(dep_clay)) AS earliest_departure_time,
  FORMAT_TIME('%H:%M:%S', MAX(arr_sac))  AS latest_arrival_time
FROM trips_with_info
GROUP BY trip_headsign
ORDER BY trip_headsign;