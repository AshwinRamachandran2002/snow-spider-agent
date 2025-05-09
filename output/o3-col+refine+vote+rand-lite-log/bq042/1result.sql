-- Average temperature, wind speed, and precipitation for LaGuardia (station 725030)
-- on June 12 for each year 2011-2020
SELECT
  2000 + CAST(_TABLE_SUFFIX AS INT64)               AS year,
  ROUND(AVG(temp), 2)                              AS avg_temp_f,
  ROUND(AVG(SAFE_CAST(wdsp AS FLOAT64)), 2)        AS avg_wdsp_knots,
  ROUND(AVG(prcp), 2)                              AS prcp_in
FROM  `bigquery-public-data.noaa_gsod.gsod20*`
WHERE 2000 + CAST(_TABLE_SUFFIX AS INT64) BETWEEN 2011 AND 2020
  AND stn = '725030'    -- LaGuardia Airport
  AND mo  = '06'
  AND da  = '12'
GROUP BY year
ORDER BY year;