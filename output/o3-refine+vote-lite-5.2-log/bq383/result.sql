WITH last_15_days AS (
  SELECT
    SAFE_CAST(_TABLE_SUFFIX AS INT64)              AS year,
    `date`,
    element,
    value
  FROM `bigquery-public-data.ghcn_d.ghcnd_*`
  WHERE
        _TABLE_SUFFIX IN ('2013','2014','2015','2016')   -- years of interest
    AND id        = 'USW00094846'                         -- target station
    AND qflag IS NULL                                     -- validated data only
    AND value IS NOT NULL
    AND element IN ('PRCP','TMIN','TMAX')                 -- needed variables
    AND EXTRACT(MONTH FROM `date`) = 12                   -- December
    AND EXTRACT(DAY   FROM `date`) BETWEEN 17 AND 31      -- last 15 days
)

SELECT
  year,
  MAX(CASE WHEN element = 'PRCP' THEN value END) / 10.0 AS max_precip_mm,   -- highest precipitation (mm)
  MIN(CASE WHEN element = 'TMIN' THEN value END) / 10.0 AS min_tmin_c,      -- lowest minimum temperature (°C)
  MAX(CASE WHEN element = 'TMAX' THEN value END) / 10.0 AS max_tmax_c       -- highest maximum temperature (°C)
FROM last_15_days
GROUP BY year
ORDER BY year;