-- Average temp (°F), wind speed (knots) and precipitation (inches)
-- for LaGuardia Airport (station 725030) on 12-Jun, 2011-2020
SELECT
  year,
  AVG(temp)                                        AS avg_temperature_f,
  AVG(SAFE_CAST(wdsp AS FLOAT64))                  AS avg_wind_speed_knots,
  AVG(prcp)                                        AS precipitation_inches
FROM `bigquery-public-data.noaa_gsod.gsod*`
WHERE _TABLE_SUFFIX IN ('2011','2012','2013','2014','2015',
                        '2016','2017','2018','2019','2020')
  AND stn = '725030'      -- LaGuardia USAF ID
  AND mo  = '06'          -- June
  AND da  = '12'          -- 12-Jun
GROUP BY year
ORDER BY year;