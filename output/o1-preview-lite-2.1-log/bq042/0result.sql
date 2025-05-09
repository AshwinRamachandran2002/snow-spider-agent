SELECT 
  CONCAT(year, '-', mo, '-', da) AS Date,
  CAST(temp AS FLOAT64) AS Mean_Temperature_F,
  CAST(wdsp AS FLOAT64) AS Average_Wind_Speed_knots,
  CAST(prcp AS FLOAT64) AS Total_Precipitation_inches
FROM `bigquery-public-data.noaa_gsod.gsod*`
WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'
  AND stn = '725030' AND wban = '14732'
  AND mo = '06' AND da = '12'
ORDER BY CAST(year AS INT64);