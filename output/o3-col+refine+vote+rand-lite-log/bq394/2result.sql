-- Top-3 year-/month combinations (2010-2014) with the smallest
-- total pair-wise difference among average Air, Wet-bulb,
-- Dew-point and Sea-surface temperatures
WITH union_data AS (
  SELECT
    year,
    month,
    air_temperature,
    wetbulb_temperature,
    dewpoint_temperature,
    sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_201*`
  WHERE year BETWEEN 2010 AND 2014
),
monthly_avgs AS (
  SELECT
    year,
    month,
    AVG(air_temperature)      AS avg_air,
    AVG(wetbulb_temperature)  AS avg_wbt,
    AVG(dewpoint_temperature) AS avg_dewp,
    AVG(sea_surface_temp)     AS avg_sst
  FROM union_data
  GROUP BY year, month
),
scored AS (
  SELECT
    year,
    month,
    ABS(avg_air - avg_wbt)  +
    ABS(avg_air - avg_dewp) +
    ABS(avg_air - avg_sst)  +
    ABS(avg_wbt - avg_dewp) +
    ABS(avg_wbt - avg_sst)  +
    ABS(avg_dewp - avg_sst)   AS sum_abs_diff
  FROM monthly_avgs
)
SELECT
  year,
  month,
  ROUND(sum_abs_diff, 4) AS sum_abs_diff
FROM scored
ORDER BY sum_abs_diff
LIMIT 3;