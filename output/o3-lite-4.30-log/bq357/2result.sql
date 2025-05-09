WITH all_obs AS (
  SELECT year, month, day, latitude, longitude, wind_speed
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2005` UNION ALL
  SELECT year, month, day, latitude, longitude, wind_speed
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2006` UNION ALL
  SELECT year, month, day, latitude, longitude, wind_speed
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2007` UNION ALL
  SELECT year, month, day, latitude, longitude, wind_speed
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2008` UNION ALL
  SELECT year, month, day, latitude, longitude, wind_speed
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2009` UNION ALL
  SELECT year, month, day, latitude, longitude, wind_speed
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2010` UNION ALL
  SELECT year, month, day, latitude, longitude, wind_speed
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2011` UNION ALL
  SELECT year, month, day, latitude, longitude, wind_speed
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2012` UNION ALL
  SELECT year, month, day, latitude, longitude, wind_speed
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2013` UNION ALL
  SELECT year, month, day, latitude, longitude, wind_speed
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2014` UNION ALL
  SELECT year, month, day, latitude, longitude, wind_speed
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2015`
)
SELECT
  ROUND(AVG(latitude), 4)  AS latitude,
  ROUND(AVG(longitude), 4) AS longitude,
  DATE(year, month, day)   AS date,
  ROUND(AVG(wind_speed) / 10, 4) AS avg_wind_speed_m_s  -- convert tenths m/s to m/s
FROM all_obs
WHERE wind_speed IS NOT NULL
  AND NOT IS_NAN(wind_speed)
  AND year BETWEEN 2005 AND 2015
GROUP BY date
ORDER BY avg_wind_speed_m_s DESC, date
LIMIT 5;