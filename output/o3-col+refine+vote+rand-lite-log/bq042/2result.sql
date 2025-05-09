-- Average temperature, wind speed, and precipitation at LaGuardia Airport (station 725030)
-- on June 12 for each year 2011-2020.
SELECT
  CAST(_TABLE_SUFFIX AS INT64)                AS year,
  AVG(temp)                                   AS avg_temp_f,
  AVG(CAST(wdsp AS FLOAT64))                  AS avg_wind_knots,
  AVG(prcp)                                   AS prcp_inches
FROM `bigquery-public-data.noaa_gsod.gsod*`
WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'   -- target years
  AND stn = '725030'                            -- LaGuardia Airport
  AND mo  = '06'                                -- June
  AND da  = '12'                                -- 12th day
GROUP BY year
ORDER BY year;