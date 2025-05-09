/*  Highest precipitation (mm), lowest minimum temperature (°C),
    and highest maximum temperature (°C) recorded at station
    USW00094846 during the last 15 days (Dec 17–31) of each year
    2013‑2016, using only validated (qflag IS NULL) observations.      */

WITH daily AS (
  SELECT
    EXTRACT(YEAR FROM `date`)         AS year,
    element,
    value
  FROM `bigquery-public-data.ghcn_d.ghcnd_20*`
  -- the wildcard suffix after "ghcnd_20" is two digits (e.g., 13 for 2013)
  WHERE _TABLE_SUFFIX IN ('13','14','15','16')          -- 2013‑2016 tables
    AND id     = 'USW00094846'                          -- target station
    AND qflag  IS NULL                                  -- validated data
    AND value  IS NOT NULL
    AND EXTRACT(MONTH FROM `date`) = 12                 -- December only
    AND EXTRACT(DAY   FROM `date`) >= 17                -- Dec 17‑31
    AND EXTRACT(YEAR  FROM `date`) BETWEEN 2013 AND 2016
)

SELECT
  year,
  MAX(CASE WHEN element = 'PRCP' THEN value END) / 10.0 AS max_precip_mm,
  MIN(CASE WHEN element = 'TMIN' THEN value END) / 10.0 AS min_tmin_c,
  MAX(CASE WHEN element = 'TMAX' THEN value END) / 10.0 AS max_tmax_c
FROM daily
GROUP BY year
ORDER BY year;