SELECT
  CAST(t.bike_number AS STRING) AS travel_coordinates,
  ROUND(
    SUM(
      ST_DISTANCE(
        ST_GEOGPOINT(s1.longitude, s1.latitude),
        ST_GEOGPOINT(s2.longitude, s2.latitude)
      )
    ) / 1000,
    4
  ) AS cumulative_travel_distance
FROM `bigquery-public-data.san_francisco.bikeshare_trips`    AS t
JOIN `bigquery-public-data.san_francisco.bikeshare_stations` AS s1
  ON t.start_station_id = s1.station_id
JOIN `bigquery-public-data.san_francisco.bikeshare_stations` AS s2
  ON t.end_station_id   = s2.station_id
GROUP BY travel_coordinates
ORDER BY cumulative_travel_distance DESC, travel_coordinates;