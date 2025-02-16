-- Task: Retrieve the mean temperature (temp) in Fahrenheit, average wind speed (wdsp) in knots, and total precipitation (prcp) in inches for LaGuardia Airport (station ID '725030', WBAN '14732') on June 12 for each year from 2011 through 2020. Replace invalid or missing values (denoted by placeholder values 9999.9 for temp, '999.9' for wdsp, and 99.99 for prcp) with NULL. Construct the date from the 'year', 'mo', and 'da' columns, and order the results by year.
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