-- Average temperature, wind speed, and precipitation at LaGuardia (station 725030)
-- on June 12 for each year 2011-2020
SELECT
  CAST('20' || _TABLE_SUFFIX AS INT64)                AS year,
  ROUND(AVG(temp), 2)                                 AS avg_temp_f,                -- °F
  ROUND((AVG(temp) - 32) / 1.8, 2)                    AS avg_temp_c,                -- °C
  ROUND(AVG(CAST(wdsp AS FLOAT64)) * 1.15078, 2)      AS avg_wind_mph,              -- mph
  ROUND(AVG(NULLIF(prcp, 99.99)), 2)                  AS precip_in                  -- inches
FROM `bigquery-public-data.noaa_gsod.gsod20*`
WHERE _TABLE_SUFFIX BETWEEN '11' AND '20'             -- 2011-2020 tables
  AND stn = '725030'                                  -- LaGuardia Airport
  AND mo = '06'                                       -- June
  AND da = '12'                                       -- 12th
GROUP BY year
ORDER BY year;