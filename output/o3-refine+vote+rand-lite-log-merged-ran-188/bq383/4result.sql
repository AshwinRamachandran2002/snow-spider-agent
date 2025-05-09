WITH daily AS (
  SELECT
    SAFE_CAST(_TABLE_SUFFIX AS INT64) AS year,
    `date`,
    element,
    value
  FROM `bigquery-public-data.ghcn_d.ghcnd_*`
  WHERE SAFE_CAST(_TABLE_SUFFIX AS INT64) BETWEEN 2013 AND 2016           -- years 2013‑2016
    AND id = 'USW00094846'                                                -- station of interest
    AND qflag IS NULL                                                     -- use only validated data
    AND value IS NOT NULL
    AND element IN ('PRCP','TMAX','TMIN')                                 -- requested elements
    AND EXTRACT(MONTH FROM `date`) = 12 AND EXTRACT(DAY FROM `date`) >= 17 -- last 15 days of year
)

SELECT
  year,
  MAX(IF(element = 'PRCP', value, NULL)) / 10 AS max_precip_mm,  -- tenths‑mm → mm
  MIN(IF(element = 'TMIN', value, NULL)) / 10 AS min_temp_c,     -- tenths‑°C → °C
  MAX(IF(element = 'TMAX', value, NULL)) / 10 AS max_temp_c      -- tenths‑°C → °C
FROM daily
GROUP BY year
ORDER BY year;