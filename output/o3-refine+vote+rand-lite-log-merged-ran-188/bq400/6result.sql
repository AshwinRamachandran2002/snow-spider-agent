WITH
-- ------------------------------------------------------------------
-- stop_ids (as STRING) for the two stops of interest
-- ------------------------------------------------------------------
clay AS (
  SELECT stop_id                                    -- STRING
  FROM `bigquery-public-data.san_francisco_transit_muni.stops`
  WHERE stop_name = 'Clay St & Drumm St'
),
sacramento AS (
  SELECT stop_id                                    -- STRING
  FROM `bigquery-public-data.san_francisco_transit_muni.stops`
  WHERE stop_name = 'Sacramento St & Davis St'
),

-- ------------------------------------------------------------------
-- For every trip, capture the sequence numbers and times
-- at the two stops (only trips visiting at least one of them)
-- ------------------------------------------------------------------
trip_pair AS (
  SELECT
    CAST(st.trip_id AS STRING) AS trip_id,          -- convert to STRING
    MAX(IF(CAST(st.stop_id AS STRING) IN (SELECT stop_id FROM clay) ,
            st.stop_sequence, NULL))                                  AS clay_seq,
    MAX(IF(CAST(st.stop_id AS STRING) IN (SELECT stop_id FROM clay) ,
            st.departure_time, NULL))                                 AS clay_dep_time,
    MAX(IF(CAST(st.stop_id AS STRING) IN (SELECT stop_id FROM sacramento) ,
            st.stop_sequence, NULL))                                  AS sac_seq,
    MAX(IF(CAST(st.stop_id AS STRING) IN (SELECT stop_id FROM sacramento) ,
            st.arrival_time , NULL))                                  AS sac_arr_time
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` st
  WHERE CAST(st.stop_id AS STRING) IN (
          SELECT stop_id FROM clay
          UNION ALL
          SELECT stop_id FROM sacramento
        )
  GROUP BY trip_id
),

-- ------------------------------------------------------------------
-- Keep only the trips where Clay precedes Sacramento
-- ------------------------------------------------------------------
good_trips AS (
  SELECT
    tp.trip_id,
    tr.route_id,
    tr.trip_headsign,
    tp.clay_dep_time,
    tp.sac_arr_time
  FROM trip_pair tp
  JOIN `bigquery-public-data.san_francisco_transit_muni.trips` tr
    ON tr.trip_id = tp.trip_id
  WHERE tp.clay_seq IS NOT NULL
    AND tp.sac_seq  IS NOT NULL
    AND tp.clay_seq < tp.sac_seq                 -- correct direction
)

-- ------------------------------------------------------------------
-- Final result per route
-- ------------------------------------------------------------------
SELECT
  route_id,
  ANY_VALUE(trip_headsign)                    AS trip_headsign,
  FORMAT_TIME('%H:%M:%S', MIN(clay_dep_time)) AS earliest_departure_clay,
  FORMAT_TIME('%H:%M:%S', MAX(sac_arr_time))  AS latest_arrival_sacramento
FROM good_trips
GROUP BY route_id
ORDER BY route_id;