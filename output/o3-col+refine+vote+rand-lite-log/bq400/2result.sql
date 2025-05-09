-- Earliest departure from “Clay St & Drumm St” and latest arrival at
-- “Sacramento St & Davis St” for the *direction where Clay precedes Sacramento*
WITH
-- 1) stop-times rows for each stop of interest
clay AS (
  SELECT
    trip_id,                        -- INT64
    stop_sequence   AS clay_seq,
    departure_time  AS depart_clay
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times`
  WHERE stop_id = 14015            -- Clay St & Drumm St
),
sac AS (
  SELECT
    trip_id,
    stop_sequence   AS sac_seq,
    arrival_time    AS arrive_sac
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times`
  WHERE stop_id = 16294            -- Sacramento St & Davis St
),
-- 2) keep only trips where the Clay stop occurs *before* the Sacramento stop
paired AS (
  SELECT
    c.trip_id,
    c.depart_clay,
    s.arrive_sac
  FROM clay c
  JOIN sac  s
    ON c.trip_id = s.trip_id
  WHERE c.clay_seq < s.sac_seq      -- ensures one direction only
),
-- 3) attach route details (route_id, headsign)
with_route AS (
  SELECT
    t.route_id,
    t.trip_headsign,
    p.depart_clay,
    p.arrive_sac
  FROM paired p
  JOIN `bigquery-public-data.san_francisco_transit_muni.trips` t
    ON t.trip_id = CAST(p.trip_id AS STRING)   -- INT64 → STRING
),
-- 4) aggregate earliest departure / latest arrival
agg AS (
  SELECT
    route_id,
    trip_headsign,
    MIN(depart_clay) AS earliest_depart_clay,
    MAX(arrive_sac)  AS latest_arrive_sac
  FROM with_route
  GROUP BY route_id, trip_headsign
)
-- 5) present results in HH:MM:SS format
SELECT
  route_id,
  trip_headsign,
  FORMAT_TIME('%H:%M:%S', earliest_depart_clay) AS earliest_depart_from_clay,
  FORMAT_TIME('%H:%M:%S', latest_arrive_sac)    AS latest_arrive_to_sacramento
FROM agg
ORDER BY route_id, trip_headsign;