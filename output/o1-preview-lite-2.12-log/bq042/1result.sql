SELECT
  CAST(year AS INT64) AS Year,
  NULLIF(temp, 9999.9) AS Avg_Temperature,
  NULLIF(CAST(wdsp AS FLOAT64), 999.9) AS Avg_Wind_Speed,
  NULLIF(prcp, 99.99) AS Precipitation
FROM
  `bigquery-public-data.noaa_gsod.gsod*`
WHERE
  stn = '725030'
  AND mo = '06'
  AND da = '12'
  AND _TABLE_SUFFIX BETWEEN '2011' AND '2020'
ORDER BY
  Year;