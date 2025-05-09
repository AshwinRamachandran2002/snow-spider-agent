SELECT
  t."bike_number",
  ROUND(SUM(
    ST_DISTANCE(
      ST_MAKEPOINT(s_start."longitude", s_start."latitude"),
      ST_MAKEPOINT(s_end."longitude", s_end."latitude")
    )
  ), 4) AS "total_distance_meters"
FROM SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_TRIPS t
JOIN SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_STATIONS s_start
  ON t."start_station_id" = s_start."station_id"
JOIN SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_STATIONS s_end
  ON t."end_station_id" = s_end."station_id"
GROUP BY t."bike_number";