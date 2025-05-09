WITH
/* stop_ids for the two stops of interest                                  */
clay AS (
    SELECT TO_NUMBER("stop_id") AS clay_stop_id
    FROM   SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOPS
    WHERE  "stop_name" = 'Clay St & Drumm St'
),
sac AS (
    SELECT TO_NUMBER("stop_id") AS sac_stop_id
    FROM   SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOPS
    WHERE  "stop_name" = 'Sacramento St & Davis St'
),

/* stop-times rows for each stop                                           */
clay_st AS (
    SELECT
           CAST("trip_id" AS VARCHAR)     AS trip_id,
           "departure_time"               AS clay_departure_time,
           "stop_sequence"                AS clay_seq
    FROM   SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOP_TIMES
    WHERE  "stop_id" IN (SELECT clay_stop_id FROM clay)
),
sac_st AS (
    SELECT
           CAST("trip_id" AS VARCHAR)     AS trip_id,
           "arrival_time"                 AS sac_arrival_time,
           "stop_sequence"                AS sac_seq
    FROM   SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOP_TIMES
    WHERE  "stop_id" IN (SELECT sac_stop_id FROM sac)
),

/* keep only trips where Clay precedes Sacramento                          */
ordered AS (
    SELECT
           c.trip_id,
           c.clay_departure_time AS clay_departure,
           s.sac_arrival_time    AS sac_arrival
    FROM   clay_st c
    JOIN   sac_st  s
           ON c.trip_id = s.trip_id
    WHERE  c.clay_seq < s.sac_seq
),

/* attach route & headsign information                                     */
trip_route AS (
    SELECT
           o.trip_id,
           o.clay_departure,
           o.sac_arrival,
           t."route_id",
           t."trip_headsign"
    FROM   ordered o
    JOIN   SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.TRIPS t
           ON o.trip_id = t."trip_id"
)

/* earliest departure from Clay & latest arrival at Sacramento per route   */
SELECT
    "route_id",
    "trip_headsign",
    TO_CHAR(MIN(clay_departure), 'HH24:MI:SS') AS "earliest_departure_from_clay",
    TO_CHAR(MAX(sac_arrival),   'HH24:MI:SS')  AS "latest_arrival_at_sacramento"
FROM   trip_route
GROUP  BY "route_id", "trip_headsign"
ORDER  BY "route_id", "trip_headsign";