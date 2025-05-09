WITH wanted_stops AS (
    -- stop_ids for the two stops we care about
    SELECT 
        "stop_id"::VARCHAR AS stop_id,
        "stop_name"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOPS
    WHERE "stop_name" IN ('Clay St & Drumm St', 'Sacramento St & Davis St')
),
trip_stops AS (
    -- stop-times records only for those two stops
    SELECT
        st."trip_id",
        ws."stop_name",
        st."stop_sequence",
        st."arrival_time",
        st."departure_time"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOP_TIMES st
    JOIN wanted_stops ws
      ON ws.stop_id = CAST(st."stop_id" AS VARCHAR)
),
trip_pairs AS (
    -- for every trip, capture the first Clay row and (latest) Sacramento row
    SELECT
        "trip_id",
        MIN(CASE WHEN "stop_name" = 'Clay St & Drumm St'        THEN "stop_sequence" END) AS clay_seq,
        MIN(CASE WHEN "stop_name" = 'Clay St & Drumm St'        THEN "departure_time" END) AS clay_departure,
        MIN(CASE WHEN "stop_name" = 'Sacramento St & Davis St'  THEN "stop_sequence" END) AS sac_seq,
        MAX(CASE WHEN "stop_name" = 'Sacramento St & Davis St'  THEN "arrival_time"  END) AS sac_arrival
    FROM trip_stops
    GROUP BY "trip_id"
),
valid_trips AS (
    -- keep only trips where Clay occurs before Sacramento
    SELECT *
    FROM trip_pairs
    WHERE clay_seq IS NOT NULL
      AND sac_seq  IS NOT NULL
      AND clay_seq < sac_seq
)
SELECT
    tr."route_id",
    tr."trip_headsign",
    TO_CHAR( MIN(vt.clay_departure) , 'HH24:MI:SS') AS "earliest_departure_from_Clay",
    TO_CHAR( MAX(vt.sac_arrival)    , 'HH24:MI:SS') AS "latest_arrival_at_Sacramento"
FROM valid_trips vt
JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.TRIPS tr
  ON tr."trip_id" = vt."trip_id"
GROUP BY
    tr."route_id",
    tr."trip_headsign"
ORDER BY
    tr."route_id";