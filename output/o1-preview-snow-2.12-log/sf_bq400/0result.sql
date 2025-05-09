SELECT 
  TO_CHAR(st1."arrival_time", 'HH24:MI:SS') AS "start_time", 
  TO_CHAR(st2."arrival_time", 'HH24:MI:SS') AS "end_time",
  tr."trip_headsign"
FROM "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_TRANSIT_MUNI"."TRIPS" tr
JOIN "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_TRANSIT_MUNI"."STOP_TIMES" st1
  ON tr."trip_id" = st1."trip_id"
JOIN "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_TRANSIT_MUNI"."STOP_TIMES" st2
  ON st1."trip_id" = st2."trip_id"
WHERE st1."stop_id" = 14015  -- 'Clay St & Drumm St'
  AND st2."stop_id" = 16294  -- 'Sacramento St & Davis St'
  AND st1."stop_sequence" < st2."stop_sequence"
  AND tr."direction" = 'I'  -- One direction only
ORDER BY "start_time", tr."trip_id";