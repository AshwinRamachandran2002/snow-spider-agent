SELECT
  CAST(t.bike_number AS STRING)                                  AS travel_coordinates,
  ROUND(
    SUM(
      ST_DISTANCE(
        ST_GEOGPOINT(s_start.longitude, s_start.latitude),
        ST_GEOGPOINT(s_end.longitude,   s_end.latitude)
      ) / 1609.34                                                -- metres → miles
    ),
    4
  )                                                             AS cumulative_travel_distance
FROM `bigquery-public-data.san_francisco.bikeshare_trips`    AS t
JOIN `bigquery-public-data.san_francisco.bikeshare_stations` AS s_start
  ON t.start_station_id = s_start.station_id
JOIN `bigquery-public-data.san_francisco.bikeshare_stations` AS s_end
  ON t.end_station_id   = s_end.station_id
WHERE t.bike_number IS NOT NULL
  AND s_start.latitude  IS NOT NULL
  AND s_start.longitude IS NOT NULL
  AND s_end.latitude    IS NOT NULL
  AND s_end.longitude   IS NOT NULL
GROUP BY travel_coordinates
ORDER BY travel_coordinates;