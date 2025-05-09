WITH all_obs AS (
  SELECT
    year,
    month,
    air_temperature      AS air,
    wetbulb_temperature  AS wbt,
    dewpoint_temperature AS dpt,
    sea_surface_temp     AS sst
  FROM (
        SELECT * FROM `bigquery-public-data.noaa_icoads.icoads_core_2010`
    UNION ALL
        SELECT * FROM `bigquery-public-data.noaa_icoads.icoads_core_2011`
    UNION ALL
        SELECT * FROM `bigquery-public-data.noaa_icoads.icoads_core_2012`
    UNION ALL
        SELECT * FROM `bigquery-public-data.noaa_icoads.icoads_core_2013`
    UNION ALL
        SELECT * FROM `bigquery-public-data.noaa_icoads.icoads_core_2014`
  )
  WHERE year BETWEEN 2010 AND 2014
    AND air_temperature      IS NOT NULL
    AND wetbulb_temperature  IS NOT NULL
    AND dewpoint_temperature IS NOT NULL
    AND sea_surface_temp     IS NOT NULL
),
monthly_means AS (
  SELECT
    year,
    month,
    AVG(air) AS avg_air,
    AVG(wbt) AS avg_wbt,
    AVG(dpt) AS avg_dpt,
    AVG(sst) AS avg_sst
  FROM all_obs
  GROUP BY year, month
),
monthly_scores AS (
  SELECT
    year,
    month,
    ABS(avg_air - avg_wbt) +
    ABS(avg_air - avg_dpt) +
    ABS(avg_air - avg_sst) +
    ABS(avg_wbt - avg_dpt) +
    ABS(avg_wbt - avg_sst) +
    ABS(avg_dpt - avg_sst) AS sum_abs_diff
  FROM monthly_means
)
SELECT
  year,
  month,
  ROUND(sum_abs_diff, 4) AS sum_abs_diff
FROM monthly_scores
ORDER BY sum_abs_diff, year, month
LIMIT 3;