WITH "CLAY" AS (
    SELECT 
        st."trip_id",
        st."stop_sequence"            AS clay_seq,
        st."departure_time"           AS clay_dep
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI."STOP_TIMES"   st
    JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI."STOPS"        s
          ON s."stop_id" = TO_VARCHAR(st."stop_id")
    WHERE s."stop_name" = 'Clay St & Drumm St'
), 
"SACRAMENTO" AS (
    SELECT 
        st."trip_id",
        st."stop_sequence"            AS sac_seq,
        st."arrival_time"             AS sac_arr
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI."STOP_TIMES"   st
    JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI."STOPS"        s
          ON s."stop_id" = TO_VARCHAR(st."stop_id")
    WHERE s."stop_name" = 'Sacramento St & Davis St'
), 
"QUALIFIED_TRIPS" AS (
    SELECT 
        c."trip_id",
        c.clay_dep,
        s.sac_arr
    FROM "CLAY" c
    JOIN "SACRAMENTO" s
          ON c."trip_id" = s."trip_id"
    -- keep only the direction where Clay precedes Sacramento
    WHERE c.clay_seq < s.sac_seq
)
SELECT
    r."route_short_name"                               AS "ROUTE",
    t."trip_headsign"                                  AS "TRIP_HEADSIGN",
    TO_CHAR(MIN(q.clay_dep), 'HH24:MI:SS')             AS "EARLIEST_CLAY_DEPARTURE",
    TO_CHAR(MAX(q.sac_arr),  'HH24:MI:SS')             AS "LATEST_SACRAMENTO_ARRIVAL"
FROM "QUALIFIED_TRIPS"             q
JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI."TRIPS"   t
      ON q."trip_id" = t."trip_id"
JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI."ROUTES"  r
      ON t."route_id" = r."route_id"
GROUP BY 
    r."route_short_name",
    t."trip_headsign"
ORDER BY 
    r."route_short_name" NULLS LAST;