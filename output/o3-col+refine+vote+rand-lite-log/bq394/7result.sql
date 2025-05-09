WITH monthly_avgs AS (
  SELECT
    year,
    month,
    AVG(air_temperature)      AS avg_air,
    AVG(wetbulb_temperature)  AS avg_wet,
    AVG(dewpoint_temperature) AS avg_dew,
    AVG(sea_surface_temp)     AS avg_sst
  FROM `bigquery-public-data.noaa_icoads.icoads_core_201*`
  -- tables matched are 2010-2019; keep only 2010-2014 via the single-digit suffix
  WHERE _TABLE_SUFFIX IN ('0','1','2','3','4')   -- 2010-2014
    AND air_temperature      IS NOT NULL
    AND wetbulb_temperature  IS NOT NULL
    AND dewpoint_temperature IS NOT NULL
    AND sea_surface_temp     IS NOT NULL
  GROUP BY year, month
),
differences AS (
  SELECT
    year,
    month,
    -- sum of six pair-wise absolute differences
    ABS(avg_air - avg_wet) +
    ABS(avg_air - avg_dew) +
    ABS(avg_air - avg_sst) +
    ABS(avg_wet - avg_dew) +
    ABS(avg_wet - avg_sst) +
    ABS(avg_dew - avg_sst) AS sum_abs_diff
  FROM monthly_avgs
)
SELECT
  year,
  month,
  ROUND(sum_abs_diff, 3) AS sum_abs_diff
FROM differences
ORDER BY sum_abs_diff
LIMIT 3;