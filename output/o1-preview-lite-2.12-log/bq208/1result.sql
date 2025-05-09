SELECT
  s.usaf AS station_id,
  s.name AS station_name,
  COUNT(g.temp) AS num_valid_temperature_observations
FROM
  `bigquery-public-data.noaa_gsod.stations` AS s
JOIN (
  SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2011`
  UNION ALL
  SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2012`
  UNION ALL
  SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2013`
  UNION ALL
  SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2014`
  UNION ALL
  SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2015`
  UNION ALL
  SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2016`
  UNION ALL
  SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2017`
  UNION ALL
  SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2018`
  UNION ALL
  SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2019`
  UNION ALL
  SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2020`
) AS g
ON
  s.usaf = g.stn AND s.wban = g.wban
WHERE
  s.lat IS NOT NULL AND s.lon IS NOT NULL AND s.lat != 0 AND s.lon != 0
  AND ST_DWITHIN(
    ST_GEOGPOINT(s.lon, s.lat),
    ST_GEOGPOINT(-73.7640, 41.1970),
    20 * 1609.344  -- Convert miles to meters
  )
  AND g.temp != 9999.9
GROUP BY
  s.usaf,
  s.name;