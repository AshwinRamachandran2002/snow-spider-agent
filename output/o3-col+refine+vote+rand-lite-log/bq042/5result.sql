-- Average daily weather for LaGuardia Airport (USAF 725030) on 12-Jun, 2011-2020
SELECT
  CAST(_TABLE_SUFFIX AS INT64)                                               AS year,
  ROUND(AVG(temp), 1)                                                        AS avg_temp_f,
  ROUND(AVG(CAST(NULLIF(wdsp, '999.9') AS FLOAT64)), 1)                      AS avg_wdsp_kts,
  ROUND(AVG(CASE WHEN prcp = 99.99 THEN NULL ELSE prcp END), 2)              AS avg_prcp_in
FROM
  `bigquery-public-data.noaa_gsod.gsod*`
WHERE
  _TABLE_SUFFIX BETWEEN '2011' AND '2020'      -- years of interest
  AND stn = '725030'                           -- LaGuardia Airport
  AND mo  = '06'                               -- June
  AND da  = '12'                               -- 12-Jun
GROUP BY
  year
ORDER BY
  year;