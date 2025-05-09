WITH all_years AS (
  SELECT year,
         month,
         air_temperature,
         wetbulb_temperature,
         dewpoint_temperature,
         sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2010`
  UNION ALL
  SELECT year,
         month,
         air_temperature,
         wetbulb_temperature,
         dewpoint_temperature,
         sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2011`
  UNION ALL
  SELECT year,
         month,
         air_temperature,
         wetbulb_temperature,
         dewpoint_temperature,
         sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2012`
  UNION ALL
  SELECT year,
         month,
         air_temperature,
         wetbulb_temperature,
         dewpoint_temperature,
         sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2013`
  UNION ALL
  SELECT year,
         month,
         air_temperature,
         wetbulb_temperature,
         dewpoint_temperature,
         sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2014`
),
valid_obs AS (
  SELECT *
  FROM all_years
  WHERE air_temperature     IS NOT NULL
    AND wetbulb_temperature IS NOT NULL
    AND dewpoint_temperature IS NOT NULL
    AND sea_surface_temp    IS NOT NULL
),
monthly_avg AS (
  SELECT
    year,
    month,
    AVG(air_temperature)      AS avg_air,
    AVG(wetbulb_temperature)  AS avg_wbt,
    AVG(dewpoint_temperature) AS avg_dpt,
    AVG(sea_surface_temp)     AS avg_sst
  FROM valid_obs
  GROUP BY year, month
),
diffs AS (
  SELECT
    year,
    month,
    ABS(avg_air - avg_wbt) +
    ABS(avg_air - avg_dpt) +
    ABS(avg_air - avg_sst) +
    ABS(avg_wbt - avg_dpt) +
    ABS(avg_wbt - avg_sst) +
    ABS(avg_dpt - avg_sst) AS sum_abs_diff
  FROM monthly_avg
)
SELECT
  year,
  month,
  ROUND(sum_abs_diff, 4) AS sum_abs_diff
FROM diffs
ORDER BY sum_abs_diff ASC, year, month
LIMIT 3;