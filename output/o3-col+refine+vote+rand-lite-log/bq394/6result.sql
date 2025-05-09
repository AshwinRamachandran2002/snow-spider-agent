-- Top-3 (year,month) combinations from 2010-2014 with the smallest
-- sum of absolute differences among the four monthly-mean temperatures
WITH all_obs AS (
  SELECT
    year,
    month,
    air_temperature      AS air,
    wetbulb_temperature  AS wet,
    dewpoint_temperature AS dew,
    sea_surface_temp     AS sst
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2010`
  UNION ALL
  SELECT
    year, month, air_temperature, wetbulb_temperature,
    dewpoint_temperature, sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2011`
  UNION ALL
  SELECT
    year, month, air_temperature, wetbulb_temperature,
    dewpoint_temperature, sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2012`
  UNION ALL
  SELECT
    year, month, air_temperature, wetbulb_temperature,
    dewpoint_temperature, sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2013`
  UNION ALL
  SELECT
    year, month, air_temperature, wetbulb_temperature,
    dewpoint_temperature, sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2014`
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
  WHERE air IS NOT NULL
    AND wet IS NOT NULL
    AND dew IS NOT NULL
    AND sst IS NOT NULL
  GROUP BY year, month
),
diffs AS (
  SELECT
    year,
    month,
    ABS(avg_air - avg_wet) + ABS(avg_air - avg_dew) + ABS(avg_air - avg_sst) +
    ABS(avg_wet - avg_dew) + ABS(avg_wet - avg_sst) + ABS(avg_dew - avg_sst)
      AS sum_abs_diffs
  FROM monthly_means
)
SELECT
  year,
  month,
  ROUND(sum_abs_diffs, 3) AS sum_abs_diffs
FROM diffs
ORDER BY sum_abs_diffs
LIMIT 3;