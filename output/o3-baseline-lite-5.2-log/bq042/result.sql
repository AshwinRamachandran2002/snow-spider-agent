SELECT
  2000 + CAST(_TABLE_SUFFIX AS INT64)            AS year,
  AVG(CASE WHEN temp  <  9999.9                        THEN temp                         END) AS avg_temp_f,
  AVG(CASE WHEN SAFE_CAST(wdsp AS FLOAT64) < 999.9 THEN SAFE_CAST(wdsp AS FLOAT64) END) AS avg_wind_speed_knots,
  AVG(CASE WHEN prcp  <  99.99                         THEN prcp                         END) AS precipitation_in
FROM `bigquery-public-data.noaa_gsod.gsod20*`
WHERE
      _TABLE_SUFFIX BETWEEN '11' AND '20'        -- 2011‑2020 tables
  AND stn  = '725030'                            -- LaGuardia Airport
  AND mo   = '06'                                -- June
  AND da   = '12'                                -- 12th day
GROUP BY year
ORDER BY year;