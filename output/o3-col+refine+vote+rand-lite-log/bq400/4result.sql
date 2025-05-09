-- Earliest departure from ‘Clay St & Drumm St’ and latest arrival at
-- ‘Sacramento St & Davis St’ for every (route id , trip head-sign) pair
-- where the vehicle visits Clay St & Drumm St first and Sacramento St & Davis St later.
WITH
-- 1️⃣  hard-code the two stop IDs found in the stops table
stop_ids AS (
  SELECT 14015 AS clay_stop_id,   -- Clay St & Drumm St
         16294 AS sac_stop_id    -- Sacramento St & Davis St
),

-- 2️⃣  keep only trips that contain BOTH stops and in the right order
trips_with_both AS (
  SELECT
    CAST(st.trip_id AS STRING)                    AS trip_id,
    MIN( IF(st.stop_id = (SELECT clay_stop_id FROM stop_ids),
            st.stop_sequence, NULL) )            AS clay_seq,
    MIN( IF(st.stop_id = (SELECT sac_stop_id  FROM stop_ids),
            st.stop_sequence, NULL) )            AS sac_seq,
    MIN( IF(st.stop_id = (SELECT clay_stop_id FROM stop_ids),
            st.departure_time, NULL) )           AS clay_depart_time,
    MAX( IF(st.stop_id = (SELECT sac_stop_id  FROM stop_ids),
            st.arrival_time , NULL) )            AS sac_arrival_time
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` AS st
  WHERE st.stop_id IN ( (SELECT clay_stop_id FROM stop_ids),
                        (SELECT sac_stop_id  FROM stop_ids) )
  GROUP BY trip_id
  HAVING clay_seq IS NOT NULL            -- trip contains Clay St & Drumm St
     AND sac_seq  IS NOT NULL            -- trip contains Sacramento St & Davis St
     AND clay_seq < sac_seq              -- Clay occurs before Sacramento
),

-- 3️⃣  attach route and head-sign information
trip_details AS (
  SELECT
    t.route_id,
    t.trip_headsign,
    twb.clay_depart_time,
    twb.sac_arrival_time
  FROM trips_with_both            AS twb
  JOIN `bigquery-public-data.san_francisco_transit_muni.trips` AS t
    ON t.trip_id = twb.trip_id
)

-- 4️⃣  final answer – earliest departure and latest arrival (HH:MM:SS)
SELECT
  route_id,
  trip_headsign,
  FORMAT_TIME('%H:%M:%S', MIN(clay_depart_time)) AS earliest_departure_from_clay,
  FORMAT_TIME('%H:%M:%S', MAX(sac_arrival_time)) AS latest_arrival_at_sacramento
FROM trip_details
GROUP BY route_id, trip_headsign
ORDER BY route_id, trip_headsign;