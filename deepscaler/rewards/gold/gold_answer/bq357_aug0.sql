-- Task: Retrieve the top 5 combinations of date, latitude, and longitude between the years 2005 and 2015 inclusive that have the highest average daily wind speeds, with latitude and longitude rounded to four decimal places, and the average wind speeds rounded to four decimal places. Exclude records with missing wind speed values. The date is constructed from the year, month, and day columns. Use data from the `bigquery-public-data.noaa_icoads.icoads_core_*` tables where the table suffix (_TABLE_SUFFIX) is between '2005' and '2015'. Group the data by date, latitude, and longitude, calculate the average wind speed for each group, and order the results in descending order of average wind speed.
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