SELECT
  s.id AS station_id,
  s.name AS station_name,
  CONCAT(
    CAST(ROUND(s.latitude ,4) AS STRING), ',',
    CAST(ROUND(s.longitude,4) AS STRING)
  ) AS travel_coordinates,
  ROUND(
    ST_DISTANCE(
      ST_GEOGPOINT(s.longitude, s.latitude),
      ST_GEOGPOINT(-87.6847, 41.8319)
    ) / 1000, 4
  ) AS cumulative_travel_distance_km
FROM
  `bigquery-public-data.ghcn_d.ghcnd_stations` AS s
WHERE
  ST_DISTANCE(
    ST_GEOGPOINT(s.longitude, s.latitude),
    ST_GEOGPOINT(-87.6847, 41.8319)
  ) <= 50000
ORDER BY
  cumulative_travel_distance_km,
  station_id;