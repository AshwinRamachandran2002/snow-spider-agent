SELECT start_st."departure_time" AS "start_time", end_st."arrival_time" AS "end_time", t."trip_headsign"
FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.TRIPS t
JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOP_TIMES start_st ON t."trip_id" = start_st."trip_id"
JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOP_TIMES end_st ON t."trip_id" = end_st."trip_id"
JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOPS start_s ON start_st."stop_id" = start_s."stop_id"
JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_TRANSIT_MUNI.STOPS end_s ON end_st."stop_id" = end_s."stop_id"
WHERE start_s."stop_name" = 'Clay St & Drumm St'
  AND end_s."stop_name" = 'Sacramento St & Davis St'
  AND start_st."stop_sequence" < end_st."stop_sequence"
ORDER BY start_st."departure_time";