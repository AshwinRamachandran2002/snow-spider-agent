SELECT
  e.epa_city AS City,
  ROUND(ABS(o.avg_pm25_2020 - e.avg_pm10_1990), 4) AS Difference_in_PM2_5
FROM (
  SELECT
    COALESCE(e.`city_name`, CONCAT(e.`county_name`, ', ', e.`state_name`)) AS epa_city,
    ROUND(e.`latitude`, 2) AS lat,
    ROUND(e.`longitude`, 2) AS lon,
    AVG(e.`arithmetic_mean`) AS avg_pm10_1990
  FROM `bigquery-public-data.epa_historical_air_quality.air_quality_annual_summary` e
  WHERE e.`parameter_name` = 'PM10 Total 0-10um STP'
    AND e.`year` = 1990
    AND e.`arithmetic_mean` IS NOT NULL
  GROUP BY epa_city, lat, lon
) AS e
JOIN (
  SELECT
    COALESCE(o.`city`, 'Unknown') AS openaq_city,
    ROUND(o.`latitude`, 2) AS lat,
    ROUND(o.`longitude`, 2) AS lon,
    AVG(o.`value`) AS avg_pm25_2020
  FROM `bigquery-public-data.openaq.global_air_quality` o
  WHERE o.`pollutant` = 'pm25'
    AND EXTRACT(YEAR FROM o.`timestamp`) = 2020
    AND o.`value` IS NOT NULL
  GROUP BY openaq_city, lat, lon
) AS o
ON e.lat = o.lat
AND e.lon = o.lon
ORDER BY Difference_in_PM2_5 DESC
LIMIT 3;