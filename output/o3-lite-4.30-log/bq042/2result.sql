/* Average temperature (°F), average wind speed (mph) and precipitation (in.)
   on 12‑June for LaGuardia Airport (station 725030) for each year 2011‑2020 */
WITH daily_obs AS (
    SELECT stn, year, mo, da, temp, wdsp, prcp FROM `bigquery-public-data.noaa_gsod.gsod2011`
    UNION ALL SELECT stn, year, mo, da, temp, wdsp, prcp FROM `bigquery-public-data.noaa_gsod.gsod2012`
    UNION ALL SELECT stn, year, mo, da, temp, wdsp, prcp FROM `bigquery-public-data.noaa_gsod.gsod2013`
    UNION ALL SELECT stn, year, mo, da, temp, wdsp, prcp FROM `bigquery-public-data.noaa_gsod.gsod2014`
    UNION ALL SELECT stn, year, mo, da, temp, wdsp, prcp FROM `bigquery-public-data.noaa_gsod.gsod2015`
    UNION ALL SELECT stn, year, mo, da, temp, wdsp, prcp FROM `bigquery-public-data.noaa_gsod.gsod2016`
    UNION ALL SELECT stn, year, mo, da, temp, wdsp, prcp FROM `bigquery-public-data.noaa_gsod.gsod2017`
    UNION ALL SELECT stn, year, mo, da, temp, wdsp, prcp FROM `bigquery-public-data.noaa_gsod.gsod2018`
    UNION ALL SELECT stn, year, mo, da, temp, wdsp, prcp FROM `bigquery-public-data.noaa_gsod.gsod2019`
    UNION ALL SELECT stn, year, mo, da, temp, wdsp, prcp FROM `bigquery-public-data.noaa_gsod.gsod2020`
)
SELECT
    CAST(year AS INT64)                                              AS year,
    ROUND(AVG(temp), 4)                                              AS avg_temperature_f,
    ROUND(AVG(CAST(wdsp AS FLOAT64) * 1.15078), 4)                   AS avg_wind_speed_mph,
    ROUND(AVG(prcp), 4)                                              AS precipitation_in
FROM daily_obs
WHERE stn = '725030'
  AND mo  = '06'
  AND da  = '12'
  AND temp <> 9999.9
  AND wdsp <> '999.9'
  AND prcp <> 99.99
GROUP BY year
ORDER BY year;