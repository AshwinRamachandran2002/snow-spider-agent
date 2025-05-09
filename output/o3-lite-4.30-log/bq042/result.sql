SELECT
  CAST(year AS INT64)                                   AS year,
  ROUND(AVG(temp), 4)                                   AS avg_temperature_f,
  ROUND(AVG(SAFE_CAST(wdsp AS FLOAT64)) * 1.15078, 4)   AS avg_wind_speed_mph,
  ROUND(AVG(prcp), 4)                                   AS precipitation_in
FROM (
  SELECT year, temp, wdsp, prcp FROM `bigquery-public-data.noaa_gsod.gsod2011` WHERE stn = '725030' AND mo = '06' AND da = '12'
  UNION ALL
  SELECT year, temp, wdsp, prcp FROM `bigquery-public-data.noaa_gsod.gsod2012` WHERE stn = '725030' AND mo = '06' AND da = '12'
  UNION ALL
  SELECT year, temp, wdsp, prcp FROM `bigquery-public-data.noaa_gsod.gsod2013` WHERE stn = '725030' AND mo = '06' AND da = '12'
  UNION ALL
  SELECT year, temp, wdsp, prcp FROM `bigquery-public-data.noaa_gsod.gsod2014` WHERE stn = '725030' AND mo = '06' AND da = '12'
  UNION ALL
  SELECT year, temp, wdsp, prcp FROM `bigquery-public-data.noaa_gsod.gsod2015` WHERE stn = '725030' AND mo = '06' AND da = '12'
  UNION ALL
  SELECT year, temp, wdsp, prcp FROM `bigquery-public-data.noaa_gsod.gsod2016` WHERE stn = '725030' AND mo = '06' AND da = '12'
  UNION ALL
  SELECT year, temp, wdsp, prcp FROM `bigquery-public-data.noaa_gsod.gsod2017` WHERE stn = '725030' AND mo = '06' AND da = '12'
  UNION ALL
  SELECT year, temp, wdsp, prcp FROM `bigquery-public-data.noaa_gsod.gsod2018` WHERE stn = '725030' AND mo = '06' AND da = '12'
  UNION ALL
  SELECT year, temp, wdsp, prcp FROM `bigquery-public-data.noaa_gsod.gsod2019` WHERE stn = '725030' AND mo = '06' AND da = '12'
  UNION ALL
  SELECT year, temp, wdsp, prcp FROM `bigquery-public-data.noaa_gsod.gsod2020` WHERE stn = '725030' AND mo = '06' AND da = '12'
)
WHERE temp <> 9999.9
  AND SAFE_CAST(wdsp AS FLOAT64) <> 999.9
  AND prcp <> 99.99
GROUP BY year
ORDER BY year;