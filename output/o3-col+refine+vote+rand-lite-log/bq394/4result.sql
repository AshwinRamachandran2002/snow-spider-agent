-- Top-3 months (2010-2014) with the smallest sum of absolute
-- differences between the four average temperature measures
WITH all_years AS (
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
    AVG(air_temperature)      AS avg_air,
    AVG(wetbulb_temperature)  AS avg_wet,
    AVG(dewpoint_temperature) AS avg_dew,
    AVG(sea_surface_temp)     AS avg_sst
  FROM all_years
  WHERE air_temperature     IS NOT NULL
    AND wetbulb_temperature IS NOT NULL
    AND dewpoint_temperature IS NOT NULL
    AND sea_surface_temp    IS NOT NULL
  GROUP BY year, month
),
diff_scores AS (
  SELECT
    year,
    month,
    ABS(avg_air - avg_wet) +
    ABS(avg_air - avg_dew) +
    ABS(avg_air - avg_sst) +
    ABS(avg_wet - avg_dew) +
    ABS(avg_wet - avg_sst) +
    ABS(avg_dew - avg_sst) AS sum_abs_diff
  FROM monthly_means
)
SELECT
  year,
  month,
  ROUND(sum_abs_diff, 4) AS sum_abs_diff
FROM diff_scores
ORDER BY sum_abs_diff
LIMIT 3;