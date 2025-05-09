WITH monthly_means AS (
  SELECT
    year,
    month,
    AVG(IF(IS_NAN(air_temperature)      , NULL, air_temperature     )) AS air,
    AVG(IF(IS_NAN(wetbulb_temperature)  , NULL, wetbulb_temperature )) AS wet,
    AVG(IF(IS_NAN(dewpoint_temperature) , NULL, dewpoint_temperature)) AS dew,
    AVG(IF(IS_NAN(sea_surface_temp)     , NULL, sea_surface_temp    )) AS sst
  FROM `bigquery-public-data.noaa_icoads.icoads_core_201*`
  WHERE year BETWEEN 2010 AND 2014
  GROUP BY year, month
),
pairwise_diff AS (
  SELECT
    year,
    month,
    ABS(air - wet) +
    ABS(air - dew) +
    ABS(air - sst) +
    ABS(wet - dew) +
    ABS(wet - sst) +
    ABS(dew - sst) AS sum_abs_diff
  FROM monthly_means
)
SELECT
  year,
  month,
  ROUND(sum_abs_diff, 2) AS sum_abs_diff
FROM pairwise_diff
ORDER BY sum_abs_diff
LIMIT 3;