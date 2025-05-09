-- Top-3 month–year combos (2010-2014) with the smallest total of the
-- six pair-wise absolute differences between the four mean temperature
-- variables in ICOADS.

WITH unioned AS (
  SELECT
    `year`,
    `month`,
    air_temperature,
    wetbulb_temperature,
    dewpoint_temperature,
    sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_20*`
  WHERE _TABLE_SUFFIX IN ('10', '11', '12', '13', '14')    -- 2010-2014
),

avg_month AS (
  SELECT
    `year`,
    `month`,
    AVG(air_temperature)      AS avg_air,
    AVG(wetbulb_temperature)  AS avg_wet,
    AVG(dewpoint_temperature) AS avg_dew,
    AVG(sea_surface_temp)     AS avg_sst
  FROM unioned
  GROUP BY `year`, `month`
),

scored AS (
  SELECT
    `year`,
    `month`,
    -- six pair-wise absolute differences
    ( ABS(avg_air - avg_wet) +
      ABS(avg_air - avg_dew) +
      ABS(avg_air - avg_sst) +
      ABS(avg_wet - avg_dew) +
      ABS(avg_wet - avg_sst) +
      ABS(avg_dew - avg_sst)
    ) AS sum_abs_diff
  FROM avg_month
)

SELECT
  `year`,
  `month`,
  ROUND(sum_abs_diff, 4) AS sum_abs_diff
FROM scored
ORDER BY sum_abs_diff
LIMIT 3;