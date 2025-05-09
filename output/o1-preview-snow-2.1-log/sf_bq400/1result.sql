SELECT
  t1."arrival_time" AS "start_time",
  t2."arrival_time" AS "end_time",
  tr."trip_headsign"
FROM
  SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOP_TIMES t1
JOIN
  SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOP_TIMES t2 ON t1."trip_id" = t2."trip_id"
JOIN
  SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.TRIPS tr ON t1."trip_id" = tr."trip_id"
WHERE
  t1."stop_id" = 14015  -- Clay St & Drumm St
  AND t2."stop_id" = 16294  -- Sacramento St & Davis St
  AND t1."stop_sequence" < t2."stop_sequence"
ORDER BY
  t1."arrival_time";