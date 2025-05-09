WITH lga_wban AS (
  SELECT DISTINCT wban
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE usaf = '725030'
)
SELECT
  2000 + CAST(_TABLE_SUFFIX AS INT64)                AS year,
  AVG(temp)                                          AS avg_temperature_f,
  AVG(CAST(NULLIF(wdsp, '999.9') AS FLOAT64))        AS avg_wind_speed_knots,
  AVG(NULLIF(prcp, 99.99))                           AS precipitation_inches
FROM `bigquery-public-data.noaa_gsod.gsod20*`
WHERE _TABLE_SUFFIX BETWEEN '11' AND '20'            -- tables for 2011‑2020
  AND stn = '725030'                                 -- LaGuardia Airport (USAF)
  AND wban IN (SELECT wban FROM lga_wban)            -- matching WBAN(s)
  AND mo = '06' AND da = '12'                        -- June 12 only
GROUP BY year
ORDER BY year;