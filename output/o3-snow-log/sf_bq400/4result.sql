WITH  -- get the stop_ids for the two required stops
"clay_stop" AS (
    SELECT "stop_id"
    FROM   SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOPS
    WHERE  "stop_name" = 'Clay St & Drumm St'
    LIMIT  1
),
"sac_stop" AS (
    SELECT "stop_id"
    FROM   SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOPS
    WHERE  "stop_name" = 'Sacramento St & Davis St'
    LIMIT  1
),

-- stop-times rows for each of those stops
"clay_times" AS (
    SELECT  "trip_id",
            "stop_sequence"   AS "clay_seq",
            "departure_time"  AS "clay_departure"
    FROM    SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOP_TIMES
    WHERE   "stop_id" = (SELECT "stop_id" FROM "clay_stop")
),
"sac_times"  AS (
    SELECT  "trip_id",
            "stop_sequence" AS "sac_seq",
            "arrival_time"  AS "sac_arrival"
    FROM    SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOP_TIMES
    WHERE   "stop_id" = (SELECT "stop_id" FROM "sac_stop")
),

-- trips where Clay precedes Sacramento in the sequence
"paired_trips" AS (
    SELECT  c."trip_id",
            c."clay_departure",
            s."sac_arrival"
    FROM    "clay_times" c
    JOIN    "sac_times"  s
           ON c."trip_id" = s."trip_id"
    WHERE   c."clay_seq" < s."sac_seq"
),

-- add route information and rank trips per route by earliest Clay departure
"routes_ranked" AS (
    SELECT  t."route_id",
            t."trip_headsign",
            p."clay_departure",
            p."sac_arrival",
            ROW_NUMBER() OVER (PARTITION BY t."route_id" ORDER BY p."clay_departure") AS "rn"
    FROM    "paired_trips" p
    JOIN    SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.TRIPS t
           ON t."trip_id" = p."trip_id"
),

-- aggregate to get earliest departure and latest arrival for each route
"agg_times" AS (
    SELECT  "route_id",
            MIN("clay_departure") AS "earliest_departure",
            MAX("sac_arrival")    AS "latest_arrival"
    FROM    "routes_ranked"
    GROUP BY "route_id"
),

-- pick the headsign from the trip with the earliest Clay departure (rn = 1)
"headsigns" AS (
    SELECT  "route_id",
            "trip_headsign"
    FROM    "routes_ranked"
    WHERE   "rn" = 1
)

-- final result
SELECT  a."route_id",
        h."trip_headsign",
        a."earliest_departure" AS "EARLIEST_DEPARTURE_TIME",
        a."latest_arrival"    AS "LATEST_ARRIVAL_TIME"
FROM    "agg_times" a
JOIN    "headsigns" h
      ON a."route_id" = h."route_id"
ORDER BY a."route_id";