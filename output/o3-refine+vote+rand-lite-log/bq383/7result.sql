/*  Highest precipitation (mm), lowest minimum‑temperature (°C),
    and highest maximum‑temperature (°C) recorded during the last
    15 days (Dec 17 – Dec 31) of each year 2013‑2016 for station
    USW00094846, using only validated observations (qflag IS NULL). */

WITH last_15_days AS (
  SELECT
    CAST(_TABLE_SUFFIX AS INT64)                AS year,
    element,
    value / 10.0                                AS val   -- convert tenths → full units
  FROM `bigquery-public-data.ghcn_d.ghcnd_*`
  WHERE _TABLE_SUFFIX IN ('2013','2014','2015','2016')   -- target years
    AND id    = 'USW00094846'                             -- target station
    AND qflag IS NULL                                     -- validated data only
    AND element IN ('PRCP','TMIN','TMAX')
    AND EXTRACT(MONTH FROM `date`) = 12
    AND EXTRACT(DAY   FROM `date`) BETWEEN 17 AND 31
)

SELECT
  year,
  MAX(CASE WHEN element = 'PRCP' THEN ROUND(val,4) END) AS precip_max_mm,
  MIN(CASE WHEN element = 'TMIN' THEN ROUND(val,4) END) AS tmin_min_c,
  MAX(CASE WHEN element = 'TMAX' THEN ROUND(val,4) END) AS tmax_max_c
FROM last_15_days
GROUP BY year
ORDER BY year;