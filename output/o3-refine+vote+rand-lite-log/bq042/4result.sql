-- Average daily conditions at LaGuardia Airport (USAF 725030) on June 12
-- for each year 2011‑2020
SELECT
  CAST(year AS INT64)                           AS year,
  AVG(temp)                                     AS avg_temp_f,
  AVG(SAFE_CAST(wdsp AS FLOAT64))               AS avg_wind_speed_knots,
  AVG(prcp)                                     AS precipitation_inches
FROM `bigquery-public-data.noaa_gsod.gsod20*`
WHERE
  _TABLE_SUFFIX IN ('11','12','13','14','15','16','17','18','19','20') -- 2011‑2020
  AND stn = '725030'      -- LaGuardia Airport (USAF ID)
  AND mo  = '06'          -- June
  AND da  = '12'          -- 12th day of month
  AND temp <  9999        -- filter out missing temperature
  AND prcp <  99.99       -- filter out missing precipitation
  AND SAFE_CAST(wdsp AS FLOAT64) < 999.9  -- filter out missing wind speed
GROUP BY year
ORDER BY year;