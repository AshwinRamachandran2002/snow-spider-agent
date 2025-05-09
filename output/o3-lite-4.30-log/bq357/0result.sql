SELECT
  latitude,
  longitude,
  DATE(year, month, day)                       AS date,
  ROUND(AVG(wind_speed) / 10.0, 4)             AS avg_wind_speed_m_s
FROM (
  SELECT year, month, day, latitude, longitude, wind_speed FROM `bigquery-public-data.noaa_icoads.icoads_core_2005`
  UNION ALL
  SELECT year, month, day, latitude, longitude, wind_speed FROM `bigquery-public-data.noaa_icoads.icoads_core_2006`
  UNION ALL
  SELECT year, month, day, latitude, longitude, wind_speed FROM `bigquery-public-data.noaa_icoads.icoads_core_2007`
  UNION ALL
  SELECT year, month, day, latitude, longitude, wind_speed FROM `bigquery-public-data.noaa_icoads.icoads_core_2008`
  UNION ALL
  SELECT year, month, day, latitude, longitude, wind_speed FROM `bigquery-public-data.noaa_icoads.icoads_core_2009`
  UNION ALL
  SELECT year, month, day, latitude, longitude, wind_speed FROM `bigquery-public-data.noaa_icoads.icoads_core_2010`
  UNION ALL
  SELECT year, month, day, latitude, longitude, wind_speed FROM `bigquery-public-data.noaa_icoads.icoads_core_2011`
  UNION ALL
  SELECT year, month, day, latitude, longitude, wind_speed FROM `bigquery-public-data.noaa_icoads.icoads_core_2012`
  UNION ALL
  SELECT year, month, day, latitude, longitude, wind_speed FROM `bigquery-public-data.noaa_icoads.icoads_core_2013`
  UNION ALL
  SELECT year, month, day, latitude, longitude, wind_speed FROM `bigquery-public-data.noaa_icoads.icoads_core_2014`
  UNION ALL
  SELECT year, month, day, latitude, longitude, wind_speed FROM `bigquery-public-data.noaa_icoads.icoads_core_2015`
)
WHERE year BETWEEN 2005 AND 2015
  AND wind_speed IS NOT NULL
  AND NOT IS_NAN(wind_speed)
GROUP BY date, latitude, longitude
ORDER BY avg_wind_speed_m_s DESC, date, latitude, longitude
LIMIT 5;