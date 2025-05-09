SELECT year, month,
  ROUND(
    ABS(AVG(air_temperature) - AVG(wetbulb_temperature)) +
    ABS(AVG(air_temperature) - AVG(dewpoint_temperature)) +
    ABS(AVG(air_temperature) - AVG(sea_surface_temp)),
    4
  ) AS sum_of_differences
FROM `bigquery-public-data.noaa_icoads.icoads_core_*`
WHERE _TABLE_SUFFIX BETWEEN '2010' AND '2014'
  AND year BETWEEN 2010 AND 2014
  AND air_temperature IS NOT NULL
  AND wetbulb_temperature IS NOT NULL
  AND dewpoint_temperature IS NOT NULL
  AND sea_surface_temp IS NOT NULL
  AND air_temperature BETWEEN -50 AND 50
  AND wetbulb_temperature BETWEEN -50 AND 50
  AND dewpoint_temperature BETWEEN -50 AND 50
  AND sea_surface_temp BETWEEN -2 AND 35
GROUP BY year, month
ORDER BY sum_of_differences ASC
LIMIT 3;