WITH
/* stop_id for each of the two locations */
clay AS (
    SELECT "stop_id"::TEXT AS stop_id
    FROM   SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOPS
    WHERE  "stop_name" = 'Clay St & Drumm St'
),
sac AS (
    SELECT "stop_id"::TEXT AS stop_id
    FROM   SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOPS
    WHERE  "stop_name" = 'Sacramento St & Davis St'
),
/* stop-times at the two stops (rename stop_sequence to avoid case-sensitive mismatch) */
clay_times AS (
    SELECT "trip_id"::TEXT          AS trip_id,
           "stop_sequence"          AS clay_seq,
           "departure_time"         AS dep_time
    FROM   SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOP_TIMES
    WHERE  "stop_id"::TEXT IN (SELECT stop_id FROM clay)
),
sac_times AS (
    SELECT "trip_id"::TEXT          AS trip_id,
           "stop_sequence"          AS sac_seq,
           "arrival_time"           AS arr_time
    FROM   SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOP_TIMES
    WHERE  "stop_id"::TEXT IN (SELECT stop_id FROM sac)
),
/* keep only those trips where Clay precedes Sacramento */
trip_summary AS (
    SELECT  c.trip_id,
            MIN(c.dep_time) AS clay_departure,
            MAX(s.arr_time) AS sac_arrival
    FROM    clay_times c
    JOIN    sac_times  s
           ON  c.trip_id = s.trip_id
           AND c.clay_seq < s.sac_seq
    GROUP BY c.trip_id
)
/* aggregate per route & headsign */
SELECT  tr."route_id",
        tr."trip_headsign",
        TO_CHAR(MIN(ts.clay_departure), 'HH24:MI:SS') AS "earliest_departure_from_clay",
        TO_CHAR(MAX(ts.sac_arrival)   , 'HH24:MI:SS') AS "latest_arrival_at_sacramento"
FROM    trip_summary ts
JOIN    SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.TRIPS tr
          ON tr."trip_id" = ts.trip_id
GROUP  BY tr."route_id",
          tr."trip_headsign"
ORDER  BY tr."route_id";