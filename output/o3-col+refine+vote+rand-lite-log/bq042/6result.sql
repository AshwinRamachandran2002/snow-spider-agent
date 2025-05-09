-- Average temperature, wind speed and precipitation for LaGuardia (USAF 725030)
-- on 12 June of each year 2011-2020
SELECT
  CAST(year AS INT64)                                         AS year,
  AVG(temp)                                                   AS avg_temp_f,
  AVG(CAST(NULLIF(wdsp, '999.9') AS FLOAT64))                 AS avg_wind_speed_knots,
  AVG(NULLIF(prcp, 99.99))                                    AS avg_prcp_in
FROM
  `bigquery-public-data.noaa_gsod.gsod20*`
WHERE
  _TABLE_SUFFIX BETWEEN '11' AND '20'    -- keeps 2011-2020 tables
  AND stn = '725030'                      -- LaGuardia Airport
  AND mo  = '06'                          -- June
  AND da  = '12'                          -- 12th day
GROUP BY year
ORDER BY year;