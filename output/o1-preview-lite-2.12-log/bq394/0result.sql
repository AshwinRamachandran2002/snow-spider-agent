SELECT
  year,
  month,
  ROUND(
    ABS(AVG(air_temperature) - AVG(wetbulb_temperature))
    + ABS(AVG(air_temperature) - AVG(dewpoint_temperature))
    + ABS(AVG(air_temperature) - AVG(sea_surface_temp))
    + ABS(AVG(wetbulb_temperature) - AVG(dewpoint_temperature))
    + ABS(AVG(wetbulb_temperature) - AVG(sea_surface_temp))
    + ABS(AVG(dewpoint_temperature) - AVG(sea_surface_temp)),
    4
  ) AS sum_of_differences
FROM (
  SELECT * FROM `bigquery-public-data.noaa_icoads.icoads_core_2010`
  UNION ALL
  SELECT * FROM `bigquery-public-data.noaa_icoads.icoads_core_2011`
  UNION ALL
  SELECT * FROM `bigquery-public-data.noaa_icoads.icoads_core_2012`
  UNION ALL
  SELECT * FROM `bigquery-public-data.noaa_icoads.icoads_core_2013`
  UNION ALL
  SELECT * FROM `bigquery-public-data.noaa_icoads.icoads_core_2014`
)
WHERE air_temperature IS NOT NULL
  AND wetbulb_temperature IS NOT NULL
  AND dewpoint_temperature IS NOT NULL
  AND sea_surface_temp IS NOT NULL
GROUP BY year, month
ORDER BY sum_of_differences ASC
LIMIT 3;