SELECT 
  ROUND(
    MAX(
      ST_DISTANCE(
        TO_GEOGRAPHY("start_station_geom"),
        TO_GEOGRAPHY("end_station_geom")
      ) / NULLIF("duration_sec", 0)
    ),
    1
  ) AS "highest_avg_speed_mps_1dp"
FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE."BIKESHARE_TRIPS"
WHERE ( "start_station_name" ILIKE '%berkeley%' 
        OR "end_station_name" ILIKE '%berkeley%' )
  AND ST_DISTANCE(
        TO_GEOGRAPHY("start_station_geom"),
        TO_GEOGRAPHY("end_station_geom")
      ) > 1000;