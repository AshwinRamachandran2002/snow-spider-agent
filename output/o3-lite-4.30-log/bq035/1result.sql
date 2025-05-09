SELECT
  CAST(t.bike_number AS STRING) AS travel_coordinates,
  ROUND(
    SUM(
      ST_DISTANCE(
        ST_GEOGPOINT(ss.longitude, ss.latitude),
        ST_GEOGPOINT(es.longitude, es.latitude)
      )
    ) / 1000,
    4
  ) AS cumulative_travel_distance
FROM
  `bigquery-public-data.san_francisco.bikeshare_trips`    AS t
JOIN
  `bigquery-public-data.san_francisco.bikeshare_stations` AS ss
    ON t.start_station_id = ss.station_id
JOIN
  `bigquery-public-data.san_francisco.bikeshare_stations` AS es
    ON t.end_station_id = es.station_id
WHERE
  ss.latitude  IS NOT NULL
  AND ss.longitude IS NOT NULL
  AND es.latitude IS NOT NULL
  AND es.longitude IS NOT NULL
GROUP BY
  travel_coordinates
ORDER BY
  cumulative_travel_distance DESC,
  travel_coordinates;