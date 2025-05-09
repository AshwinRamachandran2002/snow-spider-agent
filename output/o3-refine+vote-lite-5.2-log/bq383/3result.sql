/*  Peak precipitation (mm), minimum TMIN (°C), and maximum TMAX (°C)
    during the last 15 days (17‑31 Dec) of each year 2013‑2016
    for station USW00094846, using only validated records (qflag IS NULL). */

WITH last15 AS (
  SELECT
    EXTRACT(YEAR FROM `date`)            AS year,
    element,
    value / 10.0                         AS metric          -- convert tenths to mm / °C
  FROM `bigquery-public-data.ghcn_d.ghcnd_201*`
  WHERE _TABLE_SUFFIX IN ('3','4','5','6')                  -- tables 2013‑2016
    AND id = 'USW00094846'
    AND qflag IS NULL                                        -- validated data only
    AND value IS NOT NULL
    AND EXTRACT(MONTH FROM `date`) = 12                      -- December
    AND EXTRACT(DAY   FROM `date`) >= 17                     -- 17‑31 Dec
    AND element IN ('PRCP','TMIN','TMAX')
)

SELECT
  year,
  MAX(CASE WHEN element = 'PRCP' THEN metric END) AS precipitation_mm,
  MIN(CASE WHEN element = 'TMIN' THEN metric END) AS min_temp_c,
  MAX(CASE WHEN element = 'TMAX' THEN metric END) AS max_temp_c
FROM last15
GROUP BY year
ORDER BY year;