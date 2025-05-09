-- Average temp, wind speed, and precipitation at LaGuardia (USAF 725030)
-- for 12 June of each year 2011-2020
SELECT
  2000 + CAST(_TABLE_SUFFIX AS INT64)                    AS year,
  ROUND(AVG(temp),                                   2)  AS avg_temp_f,
  ROUND(AVG(CAST(NULLIF(wdsp, '999.9') AS FLOAT64)), 2)  AS avg_wind_knots,
  ROUND(AVG(prcp),                                   2)  AS prcp_inches
FROM  `bigquery-public-data.noaa_gsod.gsod20*`
WHERE stn = '725030'          -- LaGuardia Airport
  AND mo  = '06'              -- June
  AND da  = '12'              -- 12th day
  AND CAST(_TABLE_SUFFIX AS INT64) BETWEEN 11 AND 20   -- 2011-2020
GROUP BY year
ORDER BY year;