-- Task: For up to 100 trips in the San Francisco Bikeshare program, calculate the distance between their start and end stations.
SELECT t."trip_id",
       ROUND(
           ST_DISTANCE(
               TO_GEOGRAPHY('POINT(' || s_start."longitude" || ' ' || s_start."latitude" || ')'),
               TO_GEOGRAPHY('POINT(' || s_end."longitude" || ' ' || s_end."latitude" || ')')
           ), 4
       ) AS "distance_meters"
FROM SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_TRIPS t
JOIN SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_STATIONS s_start
  ON t."start_station_id" = s_start."station_id"
JOIN SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_STATIONS s_end
  ON t."end_station_id" = s_end."station_id"
LIMIT 100;