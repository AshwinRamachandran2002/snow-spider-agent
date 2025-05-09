WITH all_years AS (
  SELECT year, month, day, latitude, longitude, wind_speed FROM (
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
),
daily_avg AS (
  SELECT
    latitude,
    longitude,
    DATE(year, month, day) AS date,
    AVG(wind_speed / 10.0) AS avg_wind_speed_m_s
  FROM all_years
  WHERE wind_speed IS NOT NULL
    AND NOT IS_NAN(wind_speed)
  GROUP BY latitude, longitude, date
)
SELECT
  latitude,
  longitude,
  date,
  ROUND(avg_wind_speed_m_s, 4) AS avg_wind_speed_m_s
FROM daily_avg
ORDER BY avg_wind_speed_m_s DESC, date
LIMIT 5;