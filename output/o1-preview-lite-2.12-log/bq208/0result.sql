SELECT
  s.usaf AS station_id,
  s.name AS station_name,
  COUNT(*) AS num_valid_temperature_observations
FROM
  `bigquery-public-data.noaa_gsod.stations` AS s
JOIN
  `bigquery-public-data.noaa_gsod.gsod*` AS g
ON
  s.usaf = g.stn AND s.wban = g.wban
WHERE
  s.lat IS NOT NULL
  AND s.lon IS NOT NULL
  AND ST_DWITHIN(
    ST_GEOGPOINT(s.lon, s.lat),
    ST_GEOGPOINT(-73.7640, 41.1970),
    20 * 1609.344
  )
  AND g.temp != 9999.9
  AND CAST(_TABLE_SUFFIX AS INT64) BETWEEN 2011 AND 2020
GROUP BY
  s.usaf, s.name
ORDER BY
  num_valid_temperature_observations DESC