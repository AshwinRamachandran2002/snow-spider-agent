-- Top 3 (year, month) between 2010‑2014 with the smallest total
-- pair‑wise absolute differences among average Air‑, Wet‑bulb‑,
-- Dew‑point‑, and Sea‑surface temperatures
WITH all_years AS (
  -- 2010‒2014 ICOADS “core” tables
  SELECT year,
         month,
         air_temperature,
         wetbulb_temperature,
         dewpoint_temperature,
         sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2010`
  UNION ALL
  SELECT year, month, air_temperature, wetbulb_temperature,
         dewpoint_temperature, sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2011`
  UNION ALL
  SELECT year, month, air_temperature, wetbulb_temperature,
         dewpoint_temperature, sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2012`
  UNION ALL
  SELECT year, month, air_temperature, wetbulb_temperature,
         dewpoint_temperature, sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2013`
  UNION ALL
  SELECT year, month, air_temperature, wetbulb_temperature,
         dewpoint_temperature, sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2014`
),
monthly_means AS (
  SELECT
    year,
    month,
    AVG(air_temperature)       AS avg_air,
    AVG(wetbulb_temperature)   AS avg_wbt,
    AVG(dewpoint_temperature)  AS avg_dew,
    AVG(sea_surface_temp)      AS avg_sst
  FROM all_years
  GROUP BY year, month
  HAVING
    avg_air IS NOT NULL
    AND avg_wbt IS NOT NULL
    AND avg_dew IS NOT NULL
    AND avg_sst IS NOT NULL
),
pairwise_diff AS (
  SELECT
    year,
    month,
    -- sum of all six pair‑wise absolute differences
    ( ABS(avg_air - avg_wbt)
    + ABS(avg_air - avg_dew)
    + ABS(avg_air - avg_sst)
    + ABS(avg_wbt - avg_dew)
    + ABS(avg_wbt - avg_sst)
    + ABS(avg_dew - avg_sst) ) AS sum_abs_diff
  FROM monthly_means
)
SELECT
  year,
  month,
  ROUND(sum_abs_diff, 4) AS sum_of_abs_differences
FROM pairwise_diff
ORDER BY sum_abs_diff
LIMIT 3;