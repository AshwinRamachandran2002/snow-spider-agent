WITH all_data AS (
  SELECT
    year,
    month,
    air_temperature,
    wetbulb_temperature,
    dewpoint_temperature,
    sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2010`
  UNION ALL
  SELECT
    year,
    month,
    air_temperature,
    wetbulb_temperature,
    dewpoint_temperature,
    sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2011`
  UNION ALL
  SELECT
    year,
    month,
    air_temperature,
    wetbulb_temperature,
    dewpoint_temperature,
    sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2012`
  UNION ALL
  SELECT
    year,
    month,
    air_temperature,
    wetbulb_temperature,
    dewpoint_temperature,
    sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2013`
  UNION ALL
  SELECT
    year,
    month,
    air_temperature,
    wetbulb_temperature,
    dewpoint_temperature,
    sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2014`
),
monthly AS (
  SELECT
    year,
    month,
    AVG(air_temperature)      AS avg_air,
    AVG(wetbulb_temperature)  AS avg_wbt,
    AVG(dewpoint_temperature) AS avg_dpt,
    AVG(sea_surface_temp)     AS avg_sst
  FROM all_data
  GROUP BY year, month
)
SELECT
  year,
  month,
  ROUND(
        ABS(avg_air - avg_wbt) +
        ABS(avg_air - avg_dpt) +
        ABS(avg_air - avg_sst) +
        ABS(avg_wbt - avg_dpt) +
        ABS(avg_wbt - avg_sst) +
        ABS(avg_dpt - avg_sst)
       , 4) AS sum_abs_diff
FROM monthly
ORDER BY sum_abs_diff
LIMIT 3;