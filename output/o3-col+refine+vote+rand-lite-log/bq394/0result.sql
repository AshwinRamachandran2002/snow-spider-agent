-- Top-3 (year,month) periods from 2010-2014 whose four mean temperatures are most similar
WITH all_obs AS (
  SELECT
    year,
    month,
    air_temperature      AS air,
    wetbulb_temperature  AS wet,
    dewpoint_temperature AS dew,
    sea_surface_temp     AS sst
  FROM `bigquery-public-data.noaa_icoads.icoads_core_201*`
  -- suffix is the character(s) that replace the * : '0' for 2010, '1' for 2011, … '4' for 2014
  WHERE _TABLE_SUFFIX BETWEEN '0' AND '4'
    AND air_temperature IS NOT NULL
    AND wetbulb_temperature IS NOT NULL
    AND dewpoint_temperature IS NOT NULL
    AND sea_surface_temp IS NOT NULL
),
monthly_means AS (
  SELECT
    year,
    month,
    AVG(air) AS avg_air,
    AVG(wet) AS avg_wet,
    AVG(dew) AS avg_dew,
    AVG(sst) AS avg_sst
  FROM all_obs
  GROUP BY year, month
)
SELECT
  year,
  month,
  -- sum of the 6 absolute pair-wise differences among the four monthly means
  ABS(avg_air - avg_wet) +
  ABS(avg_air - avg_dew) +
  ABS(avg_air - avg_sst) +
  ABS(avg_wet - avg_dew) +
  ABS(avg_wet - avg_sst) +
  ABS(avg_dew - avg_sst) AS sum_of_differences
FROM monthly_means
ORDER BY sum_of_differences
LIMIT 3;