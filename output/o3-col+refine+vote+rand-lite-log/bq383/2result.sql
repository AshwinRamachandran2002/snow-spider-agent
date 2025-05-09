/* Highest validated precipitation (mm), minimum-temperature (°C) and
   maximum-temperature (°C) recorded during 17-31 Dec of each year
   2013-2016 at station USW00094846                                  */

WITH filtered AS (
  SELECT
    CAST(_TABLE_SUFFIX AS INT64)      AS yr,        -- 2013 … 2016
    element,
    value                             
  FROM `bigquery-public-data.ghcn_d.ghcnd_*`
  WHERE _TABLE_SUFFIX IN ('2013','2014','2015','2016')   -- target years
    AND id        = 'USW00094846'                        -- station
    AND element   IN ('PRCP','TMIN','TMAX')              -- wanted vars
    AND date BETWEEN DATE(CONCAT(_TABLE_SUFFIX,'-12-17'))
                   AND DATE(CONCAT(_TABLE_SUFFIX,'-12-31')) -- last 15 days
    AND qflag IS NULL                                    -- validated rows
    AND value IS NOT NULL
),
peaks AS (
  SELECT
    yr,
    element,
    MAX(value) AS max_tenth_unit        -- still in 0.1-unit scale
  FROM filtered
  GROUP BY yr, element
)

SELECT
  yr AS year,
  MAX(IF(element = 'PRCP', max_tenth_unit/10, NULL)) AS max_precip_mm,
  MAX(IF(element = 'TMIN', max_tenth_unit/10, NULL)) AS highest_min_temp_c,
  MAX(IF(element = 'TMAX', max_tenth_unit/10, NULL)) AS highest_max_temp_c
FROM peaks
GROUP BY yr
ORDER BY yr;