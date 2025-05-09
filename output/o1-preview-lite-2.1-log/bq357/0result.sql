SELECT
  DATE(CONCAT(
    CAST(year AS STRING), '-',
    LPAD(CAST(month AS STRING), 2, '0'), '-',
    LPAD(CAST(day AS STRING), 2, '0')
  )) AS Date,
  ROUND(latitude, 4) AS Latitude,
  ROUND(longitude, 4) AS Longitude,
  ROUND(AVG(wind_speed), 4) AS Average_Wind_Speed
FROM
  `bigquery-public-data.noaa_icoads.icoads_core_*`
WHERE
  _TABLE_SUFFIX BETWEEN '2005' AND '2015'
  AND wind_speed IS NOT NULL
  AND year BETWEEN 2005 AND 2015
GROUP BY
  Date, Latitude, Longitude
ORDER BY
  Average_Wind_Speed DESC
LIMIT 5;