SELECT
  year,
  temp AS Avg_Temperature,
  wdsp AS Avg_Wind_Speed,
  prcp AS Precipitation
FROM `bigquery-public-data.noaa_gsod.gsod*`
WHERE
  _TABLE_SUFFIX BETWEEN '2011' AND '2020'
  AND stn = '725030'
  AND mo = '06'
  AND da = '12'
ORDER BY year