WITH
  berkeley_stations AS (
    SELECT "station_id"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO
    WHERE "region_id" = 14
  ),
  trips_in_berkeley AS (
    SELECT *
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS t
    WHERE t."start_station_id" IN (SELECT "station_id" FROM berkeley_stations)
       OR t."end_station_id" IN (SELECT "station_id" FROM berkeley_stations)
  ),
  trips_with_distance AS (
    SELECT *,
      ST_DISTANCE(
        ST_POINT("start_station_longitude", "start_station_latitude"),
        ST_POINT("end_station_longitude", "end_station_latitude")
      ) AS "distance_meters"
    FROM trips_in_berkeley
  ),
  filtered_trips AS (
    SELECT *,
      "distance_meters" / NULLIF("duration_sec", 0) AS "average_speed_m_s"
    FROM trips_with_distance
    WHERE "distance_meters" > 1000 AND "duration_sec" > 0
  )
SELECT ROUND(MAX("average_speed_m_s"), 1) AS "highest_average_speed_m_s"
FROM filtered_trips;