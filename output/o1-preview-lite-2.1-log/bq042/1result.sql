SELECT
  DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) AS Date,
  CASE WHEN temp != 9999.9 THEN temp ELSE NULL END AS Mean_Temperature_F,
  CASE WHEN wdsp != '999.9' THEN CAST(wdsp AS FLOAT64) ELSE NULL END AS Average_Wind_Speed_knots,
  CASE WHEN prcp != 99.99 THEN prcp ELSE NULL END AS Total_Precipitation_inches
FROM
  `bigquery-public-data.noaa_gsod.gsod*`
WHERE
  _TABLE_SUFFIX BETWEEN '2011' AND '2020'
  AND stn = '725030' AND wban = '14732'
  AND mo = '06' AND da = '12'
ORDER BY
  CAST(year AS INT64);