-- Highest PRCP, lowest TMIN, and highest TMAX for the last 15 days
-- (17-31 Dec) of each year 2013-2016 at station USW00094846
SELECT
  2000 + CAST(_TABLE_SUFFIX AS INT64)                                   AS year_ending,
  MAX(CASE WHEN element = 'PRCP' THEN value END) / 10.0                 AS highest_precip_mm,   -- tenths-mm → mm
  MIN(CASE WHEN element = 'TMIN' THEN value END) / 10.0                 AS coldest_tmin_c,      -- tenths-°C → °C
  MAX(CASE WHEN element = 'TMAX' THEN value END) / 10.0                 AS warmest_tmax_c       -- tenths-°C → °C
FROM
  `bigquery-public-data.ghcn_d.ghcnd_20*`
WHERE
  _TABLE_SUFFIX IN ('13','14','15','16')                 -- 2013-2016
  AND id          = 'USW00094846'                        -- target station
  AND element     IN ('PRCP','TMIN','TMAX')              -- metrics of interest
  AND date BETWEEN DATE(2000 + CAST(_TABLE_SUFFIX AS INT64), 12, 17)
                 AND DATE(2000 + CAST(_TABLE_SUFFIX AS INT64), 12, 31) -- last 15 days
  AND value IS NOT NULL
  AND qflag IS NULL                                      -- validated data only
GROUP BY
  year_ending
ORDER BY
  year_ending;