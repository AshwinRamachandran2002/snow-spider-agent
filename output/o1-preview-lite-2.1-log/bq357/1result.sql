SELECT
  FORMAT_DATE('%Y-%m-%d', DATE(CAST(year AS INT64), CAST(month AS INT64), CAST(day AS INT64))) AS Date,
  ROUND(latitude, 4) AS Latitude,
  ROUND(longitude, 4) AS Longitude,
  ROUND(AVG(wind_speed), 4) AS Average_Wind_Speed
FROM
  `bigquery-public-data.noaa_icoads.icoads_core_*`
WHERE
  _TABLE_SUFFIX BETWEEN '2005' AND '2015'
  AND wind_speed IS NOT NULL
GROUP BY
  Date, Latitude, Longitude
ORDER BY
  Average_Wind_Speed DESC
LIMIT
  5;