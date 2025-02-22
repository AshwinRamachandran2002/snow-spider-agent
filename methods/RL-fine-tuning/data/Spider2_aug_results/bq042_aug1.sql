-- Task: Retrieve the mean temperature for LaGuardia Airport on June 12, 2020, using the station ID 725030.

SELECT
  DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) AS Date,
  CASE WHEN temp != 9999.9 THEN temp ELSE NULL END AS Mean_Temperature_F
FROM
  `bigquery-public-data.noaa_gsod.gsod2020`
WHERE
  stn = '725030' AND wban = '14732'
  AND mo = '06' AND da = '12'
ORDER BY
  CAST(year AS INT64);