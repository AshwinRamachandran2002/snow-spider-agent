WITH
-- stop_id values for both stops (may be more than one record each)
"CLAY_IDS" AS (
    SELECT TO_NUMBER("stop_id") AS "stop_id"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOPS
    WHERE "stop_name" = 'Clay St & Drumm St'
),
"SAC_IDS" AS (
    SELECT TO_NUMBER("stop_id") AS "stop_id"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOPS
    WHERE "stop_name" = 'Sacramento St & Davis St'
),

-- times and sequences at Clay St & Drumm St
"CLAY_TIMES" AS (
    SELECT
        st."trip_id",
        st."departure_time"            AS "clay_departure_time",
        st."stop_sequence"             AS "clay_seq"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOP_TIMES st
    JOIN "CLAY_IDS" c
          ON st."stop_id" = c."stop_id"
),

-- times and sequences at Sacramento St & Davis St
"SAC_TIMES" AS (
    SELECT
        st."trip_id",
        st."arrival_time"              AS "sac_arrival_time",
        st."stop_sequence"             AS "sac_seq"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOP_TIMES st
    JOIN "SAC_IDS" s
          ON st."stop_id" = s."stop_id"
),

-- retain only trips where Clay precedes Sacramento
"CANDIDATE_TRIPS" AS (
    SELECT
        c."trip_id",
        c."clay_departure_time",
        s."sac_arrival_time"
    FROM "CLAY_TIMES" c
    JOIN "SAC_TIMES" s
          ON c."trip_id" = s."trip_id"
    WHERE c."clay_seq" < s."sac_seq"
)

SELECT
    r."route_short_name"                          AS "ROUTE",
    t."trip_headsign"                             AS "TRIP_HEADSIGN",
    TO_CHAR(MIN(ct."clay_departure_time"), 'HH24:MI:SS')  AS "EARLIEST_DEPART_CLAY",
    TO_CHAR(MAX(ct."sac_arrival_time"),   'HH24:MI:SS')  AS "LATEST_ARRIVE_SACRAMENTO"
FROM "CANDIDATE_TRIPS" ct
JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.TRIPS   t
      ON ct."trip_id" = t."trip_id"
JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.ROUTES  r
      ON t."route_id" = r."route_id"
GROUP BY
    r."route_short_name",
    t."trip_headsign"
ORDER BY
    r."route_short_name" ASC NULLS LAST,
    t."trip_headsign";