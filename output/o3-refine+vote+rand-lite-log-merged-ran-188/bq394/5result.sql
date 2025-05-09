-- Top 3 (year, month) pairs, 2010‑2014, with the smallest total pair‑wise
-- differences among monthly means of air‑, wet‑bulb‑, dew‑point‑,
-- and sea‑surface temperatures
WITH combined AS (
  SELECT 2010 AS year, month, air_temperature, wetbulb_temperature,
         dewpoint_temperature, sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2010`
  UNION ALL
  SELECT 2011, month, air_temperature, wetbulb_temperature,
         dewpoint_temperature, sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2011`
  UNION ALL
  SELECT 2012, month, air_temperature, wetbulb_temperature,
         dewpoint_temperature, sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2012`
  UNION ALL
  SELECT 2013, month, air_temperature, wetbulb_temperature,
         dewpoint_temperature, sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2013`
  UNION ALL
  SELECT 2014, month, air_temperature, wetbulb_temperature,
         dewpoint_temperature, sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_2014`
),
monthly_means AS (
  SELECT
    year,
    month,
    AVG(CASE WHEN NOT IS_NAN(air_temperature)       THEN air_temperature       END) AS avg_air,
    AVG(CASE WHEN NOT IS_NAN(wetbulb_temperature)   THEN wetbulb_temperature   END) AS avg_wbt,
    AVG(CASE WHEN NOT IS_NAN(dewpoint_temperature)  THEN dewpoint_temperature  END) AS avg_dew,
    AVG(CASE WHEN NOT IS_NAN(sea_surface_temp)      THEN sea_surface_temp      END) AS avg_sst
  FROM combined
  GROUP BY year, month
),
scored AS (
  SELECT
    year,
    month,
    -- sum of all six absolute pair‑wise differences
    ( ABS(avg_air - avg_wbt) + ABS(avg_air - avg_dew) + ABS(avg_air - avg_sst)
    + ABS(avg_wbt - avg_dew) + ABS(avg_wbt - avg_sst) + ABS(avg_dew - avg_sst)
    ) AS sum_abs_diff
  FROM monthly_means
  WHERE avg_air IS NOT NULL
    AND avg_wbt IS NOT NULL
    AND avg_dew IS NOT NULL
    AND avg_sst IS NOT NULL
)
SELECT
  year,
  month AS numeric_month,
  sum_abs_diff
FROM scored
ORDER BY sum_abs_diff
LIMIT 3;