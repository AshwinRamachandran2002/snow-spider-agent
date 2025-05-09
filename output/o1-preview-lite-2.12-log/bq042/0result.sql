SELECT
  CAST(_TABLE_SUFFIX AS INT64) AS Year,
  ROUND(CAST(temp AS FLOAT64), 4) AS Avg_Temperature,
  ROUND(CAST(wdsp AS FLOAT64), 4) AS Avg_Wind_Speed,
  ROUND(CAST(prcp AS FLOAT64), 4) AS Precipitation
FROM
  `bigquery-public-data.noaa_gsod.gsod*`
WHERE
  stn = '725030' AND wban = '14732' AND
  mo = '06' AND da = '12' AND
  _TABLE_SUFFIX BETWEEN '2011' AND '2020' AND
  temp IS NOT NULL AND CAST(temp AS FLOAT64) != 9999.9 AND
  wdsp IS NOT NULL AND CAST(wdsp AS FLOAT64) != 999.9 AND
  prcp IS NOT NULL AND CAST(prcp AS FLOAT64) != 99.99
ORDER BY
  Year;