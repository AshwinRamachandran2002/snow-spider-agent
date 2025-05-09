WITH union_data AS (
  SELECT
    `year`,
    `month`,
    `air_temperature`      AS air,
    `wetbulb_temperature`  AS wet,
    `dewpoint_temperature` AS dew,
    `sea_surface_temp`     AS sst
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2010`
  UNION ALL
  SELECT
    `year`, `month`,
    `air_temperature`,
    `wetbulb_temperature`,
    `dewpoint_temperature`,
    `sea_surface_temp`
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2011`
  UNION ALL
  SELECT
    `year`, `month`,
    `air_temperature`,
    `wetbulb_temperature`,
    `dewpoint_temperature`,
    `sea_surface_temp`
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2012`
  UNION ALL
  SELECT
    `year`, `month`,
    `air_temperature`,
    `wetbulb_temperature`,
    `dewpoint_temperature`,
    `sea_surface_temp`
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2013`
  UNION ALL
  SELECT
    `year`, `month`,
    `air_temperature`,
    `wetbulb_temperature`,
    `dewpoint_temperature`,
    `sea_surface_temp`
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2014`
),
clean AS (
  SELECT *
  FROM union_data
  WHERE air IS NOT NULL
    AND wet IS NOT NULL
    AND dew IS NOT NULL
    AND sst IS NOT NULL
),
monthly_avg AS (
  SELECT
    `year`,
    `month`,
    AVG(air) AS avg_air,
    AVG(wet) AS avg_wet,
    AVG(dew) AS avg_dew,
    AVG(sst) AS avg_sst
  FROM clean
  GROUP BY `year`, `month`
)
SELECT
  `year`,
  `month`,
  ROUND(
        ABS(avg_air - avg_wet) +
        ABS(avg_air - avg_dew) +
        ABS(avg_air - avg_sst) +
        ABS(avg_wet - avg_dew) +
        ABS(avg_wet - avg_sst) +
        ABS(avg_dew - avg_sst)
       ,4) AS sum_abs_diff
FROM monthly_avg
ORDER BY sum_abs_diff, `year`, `month`
LIMIT 3;