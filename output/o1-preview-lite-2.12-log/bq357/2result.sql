SELECT
  DATE(year, month, day) AS `Date`,
  latitude AS `Latitude`,
  longitude AS `Longitude`,
  ROUND(AVG(wind_speed), 4) AS `Average_Wind_Speed`
FROM
  `bigquery-public-data.noaa_icoads.icoads_core_*`
WHERE
  _TABLE_SUFFIX BETWEEN '2005' AND '2015'
  AND wind_speed IS NOT NULL
GROUP BY
  `Date`, `Latitude`, `Longitude`
ORDER BY
  `Average_Wind_Speed` DESC
LIMIT 5;