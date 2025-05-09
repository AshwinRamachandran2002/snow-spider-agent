-- Average temperature (°F), wind speed (knots), and precipitation (inches)
-- for LaGuardia Airport (USAF 725030) on 12 June, 2011‑2020
SELECT
  CAST(year AS INT64)                                       AS year,
  AVG(IF(temp < 9999.9, temp, NULL))                        AS avg_temp_f,
  AVG(IF(SAFE_CAST(wdsp AS FLOAT64) < 999.9,
         SAFE_CAST(wdsp AS FLOAT64), NULL))                 AS avg_wind_speed_knots,
  AVG(IF(prcp < 99.99, prcp, NULL))                         AS avg_prcp_inches
FROM `bigquery-public-data.noaa_gsod.gsod20*`
WHERE _TABLE_SUFFIX IN ('11','12','13','14','15','16','17','18','19','20')  -- 2011‑2020 tables
  AND stn = '725030'        -- LaGuardia USAF ID
  AND mo  = '06'            -- June
  AND da  = '12'            -- 12th
GROUP BY year
ORDER BY year;