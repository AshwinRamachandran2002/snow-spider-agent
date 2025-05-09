/*  Earliest departure from ‘Clay St & Drumm St’ and latest arrival at
    ‘Sacramento St & Davis St’, by route, only for trips where the Clay-stop
    appears earlier in the stop sequence than the Sacramento-stop          */

WITH
clay_ids AS (          /* stop_id(s) for “Clay St & Drumm St”               */
    SELECT "stop_id"
    FROM   SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOPS
    WHERE  "stop_name" = 'Clay St & Drumm St'
),
sac_ids AS (           /* stop_id(s) for “Sacramento St & Davis St”          */
    SELECT "stop_id"
    FROM   SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOPS
    WHERE  "stop_name" = 'Sacramento St & Davis St'
),
trip_pairs AS (        /* trips containing both stops in correct order       */
    SELECT
        clay."trip_id",
        clay."departure_time"             AS clay_departure,
        sac."arrival_time"                AS sac_arrival
    FROM   SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOP_TIMES  clay
    JOIN   SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOP_TIMES  sac
           ON clay."trip_id" = sac."trip_id"
    WHERE  clay."stop_id" IN (SELECT "stop_id" FROM clay_ids)
      AND  sac."stop_id"  IN (SELECT "stop_id" FROM sac_ids)
      AND  clay."stop_sequence" < sac."stop_sequence"          -- Clay before Sacramento
),
enriched AS (          /* add route & headsign information                   */
    SELECT
        tp."trip_id",
        tp.clay_departure,
        tp.sac_arrival,
        tr."route_id",
        tr."trip_headsign"
    FROM   trip_pairs tp
    JOIN   SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.TRIPS tr
           ON tp."trip_id" = tr."trip_id"
)
SELECT
    "route_id",
    MIN("trip_headsign")                AS "trip_headsign",          -- representative head-sign
    MIN(clay_departure)                 AS "earliest_departure_clay",-- HH:MM:SS
    MAX(sac_arrival)                    AS "latest_arrival_sacramento"-- HH:MM:SS
FROM   enriched
GROUP  BY "route_id"
ORDER  BY "route_id";