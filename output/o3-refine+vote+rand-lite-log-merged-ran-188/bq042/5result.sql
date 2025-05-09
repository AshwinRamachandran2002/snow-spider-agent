-- Average temperature, wind speed, and precipitation at LaGuardia Airport (USAF 725030)
-- on June 12 for each year 2011–2020
SELECT
  CAST(_TABLE_SUFFIX AS INT64)                         AS year,
  AVG(CASE WHEN temp BETWEEN -100 AND 200 THEN temp END)                        AS avg_temp_f,
  AVG(CASE WHEN SAFE_CAST(wdsp AS FLOAT64) < 900 THEN SAFE_CAST(wdsp AS FLOAT64) END) AS avg_wind_speed_knots,
  AVG(CASE WHEN prcp < 90 THEN prcp END)                                        AS precipitation_inches
FROM `bigquery-public-data.noaa_gsod.gsod*`
WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'   -- pick yearly tables 2011‑2020
  AND stn = '725030'                           -- LaGuardia Airport USAF ID
  AND mo  = '06'                               -- June
  AND da  = '12'                               -- 12th day
GROUP BY year
ORDER BY year;