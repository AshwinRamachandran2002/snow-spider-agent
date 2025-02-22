-- Task: What are the dates between 2005 and 2015 with the highest daily average wind speeds, excluding records with missing wind speed values? Using data from tables starting with prefix 'icoads_core'.
SELECT
  DATE(CONCAT(
    CAST(`year` AS STRING), '-',
    LPAD(CAST(`month` AS STRING), 2, '0'), '-',
    LPAD(CAST(`day` AS STRING), 2, '0')
  )) AS Date,
  ROUND(AVG(`wind_speed`), 4) AS Average_Wind_Speed
FROM
  `bigquery-public-data.noaa_icoads.icoads_core_*`
WHERE
  `_TABLE_SUFFIX` BETWEEN '2005' AND '2015'
  AND `wind_speed` IS NOT NULL
  AND `year` BETWEEN 2005 AND 2015
GROUP BY
  Date
ORDER BY
  Average_Wind_Speed DESC
LIMIT 5;