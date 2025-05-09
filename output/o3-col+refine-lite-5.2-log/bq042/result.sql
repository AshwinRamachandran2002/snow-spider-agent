SELECT
  _TABLE_SUFFIX AS year ,
  AVG(temp) AS avg_temp_f ,
  AVG( SAFE_CAST(NULLIF(wdsp , '999.9') AS FLOAT64) ) AS avg_wind_speed_knots ,
  AVG( NULLIF(prcp , 99.99) ) AS prcp_inches
FROM `bigquery-public-data.noaa_gsod.gsod*`
WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'        -- years of interest
  AND stn = '725030'                                 -- LaGuardia Airport
  AND mo  = '06'                                     -- June
  AND da  = '12'                                     -- 12‑th day
GROUP BY year
ORDER BY year;