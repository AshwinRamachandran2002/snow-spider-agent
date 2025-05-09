SELECT
  CAST(year AS INT64)                                               AS year,
  ROUND(AVG(NULLIF(temp , 9999.9)), 4)                              AS avg_temperature_f,
  ROUND(AVG(NULLIF(CAST(wdsp AS FLOAT64), 999.9) * 1.15078), 4)     AS avg_wind_speed_mph,
  ROUND(AVG(NULLIF(prcp , 99.99)), 4)                               AS precipitation_in
FROM (
  SELECT year, temp, wdsp, prcp, stn, mo, da FROM `bigquery-public-data.noaa_gsod.gsod2011`
  UNION ALL SELECT year, temp, wdsp, prcp, stn, mo, da FROM `bigquery-public-data.noaa_gsod.gsod2012`
  UNION ALL SELECT year, temp, wdsp, prcp, stn, mo, da FROM `bigquery-public-data.noaa_gsod.gsod2013`
  UNION ALL SELECT year, temp, wdsp, prcp, stn, mo, da FROM `bigquery-public-data.noaa_gsod.gsod2014`
  UNION ALL SELECT year, temp, wdsp, prcp, stn, mo, da FROM `bigquery-public-data.noaa_gsod.gsod2015`
  UNION ALL SELECT year, temp, wdsp, prcp, stn, mo, da FROM `bigquery-public-data.noaa_gsod.gsod2016`
  UNION ALL SELECT year, temp, wdsp, prcp, stn, mo, da FROM `bigquery-public-data.noaa_gsod.gsod2017`
  UNION ALL SELECT year, temp, wdsp, prcp, stn, mo, da FROM `bigquery-public-data.noaa_gsod.gsod2018`
  UNION ALL SELECT year, temp, wdsp, prcp, stn, mo, da FROM `bigquery-public-data.noaa_gsod.gsod2019`
  UNION ALL SELECT year, temp, wdsp, prcp, stn, mo, da FROM `bigquery-public-data.noaa_gsod.gsod2020`
)
WHERE stn = '725030'
  AND mo  = '06'
  AND da  = '12'
GROUP BY year
ORDER BY year;