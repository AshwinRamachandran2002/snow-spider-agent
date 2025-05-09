WITH
-- stop_ids for the two stops of interest
clay_stop AS (
    SELECT "stop_id"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOPS
    WHERE LOWER("stop_name") = 'clay st & drumm st'
),
sac_stop AS (
    SELECT "stop_id"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOPS
    WHERE LOWER("stop_name") = 'sacramento st & davis st'
),

-- trips that serve both stops with Clay occurring BEFORE Sacramento
qualified_trips AS (
    SELECT
        tr."route_id",
        tr."trip_headsign",
        st_clay."departure_time" AS clay_depart_time,
        st_sac."arrival_time"  AS sac_arrive_time
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.TRIPS        tr
    JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOP_TIMES  st_clay
         ON st_clay."trip_id" = tr."trip_id"
    JOIN clay_stop cs
         ON cs."stop_id" = st_clay."stop_id"
    JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOP_TIMES  st_sac
         ON st_sac."trip_id" = tr."trip_id"
    JOIN sac_stop ss
         ON ss."stop_id" = st_sac."stop_id"
    WHERE st_clay."stop_sequence" < st_sac."stop_sequence"          -- Clay occurs before Sacramento
)

-- earliest departure from Clay and latest arrival at Sacramento
SELECT
    "route_id",
    "trip_headsign",
    TO_CHAR(MIN(clay_depart_time), 'HH24:MI:SS') AS "earliest_depart_clay",
    TO_CHAR(MAX(sac_arrive_time),  'HH24:MI:SS') AS "latest_arrive_sacramento"
FROM qualified_trips
GROUP BY "route_id", "trip_headsign"
ORDER BY "route_id", "trip_headsign";