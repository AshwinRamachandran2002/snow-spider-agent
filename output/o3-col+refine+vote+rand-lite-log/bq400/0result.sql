-- Earliest departure from “Clay St & Drumm St” (stop_id 14015) and
-- latest arrival at “Sacramento St & Davis St” (stop_id 16294)
-- for every route / head-sign where the vehicle reaches Clay before Sacramento
WITH clay AS (      -- all Clay-stop records that later reach Sacramento
  SELECT
    t.route_id,
    t.trip_headsign,
    MIN(st.departure_time) AS earliest_clay
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` AS st
  JOIN `bigquery-public-data.san_francisco_transit_muni.trips`      AS t
    ON CAST(st.trip_id AS STRING) = t.trip_id
  WHERE st.stop_id = 14015                       -- Clay St & Drumm St
    AND EXISTS (                                -- same trip later visits Sacramento
      SELECT 1
      FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` st2
      WHERE st2.trip_id      = st.trip_id
        AND st2.stop_id      = 16294           -- Sacramento St & Davis St
        AND st.stop_sequence < st2.stop_sequence )
  GROUP BY t.route_id, t.trip_headsign
),
sac AS (        -- corresponding Sacramento-stop records reached after Clay
  SELECT
    t.route_id,
    t.trip_headsign,
    MAX(st.arrival_time) AS latest_sac
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` AS st
  JOIN `bigquery-public-data.san_francisco_transit_muni.trips`      AS t
    ON CAST(st.trip_id AS STRING) = t.trip_id
  WHERE st.stop_id = 16294                       -- Sacramento St & Davis St
    AND EXISTS (                                -- same trip first visited Clay
      SELECT 1
      FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` st2
      WHERE st2.trip_id      = st.trip_id
        AND st2.stop_id      = 14015           -- Clay St & Drumm St
        AND st2.stop_sequence < st.stop_sequence )
  GROUP BY t.route_id, t.trip_headsign
)

SELECT
  c.route_id,
  c.trip_headsign,
  FORMAT_TIME('%H:%M:%S', c.earliest_clay) AS earliest_departure_from_clay,
  FORMAT_TIME('%H:%M:%S', s.latest_sac)    AS latest_arrival_at_sacramento
FROM clay c
JOIN sac  s
  ON s.route_id      = c.route_id
 AND s.trip_headsign = c.trip_headsign
ORDER BY c.route_id, c.trip_headsign;