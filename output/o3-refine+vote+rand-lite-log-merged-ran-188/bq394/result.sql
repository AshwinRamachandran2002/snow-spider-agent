/*  Top 3 (year, month) between 2010‑2014 whose four mean temperatures
    (air, wet‑bulb, dew‑point, sea‑surface) are the closest to one another  */
WITH all_records AS (
  SELECT
    year,
    month,
    -- keep only meaningful values (discard NULL / NaN)
    IF(IS_NAN(air_temperature)      OR air_temperature      IS NULL, NULL, air_temperature)       AS air_temperature,
    IF(IS_NAN(wetbulb_temperature)  OR wetbulb_temperature  IS NULL, NULL, wetbulb_temperature)   AS wetbulb_temperature,
    IF(IS_NAN(dewpoint_temperature) OR dewpoint_temperature IS NULL, NULL, dewpoint_temperature)  AS dewpoint_temperature,
    IF(IS_NAN(sea_surface_temp)     OR sea_surface_temp     IS NULL, NULL, sea_surface_temp)      AS sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_201*`
  WHERE year BETWEEN 2010 AND 2014          -- years of interest
),

monthly_means AS (
  SELECT
    year,
    month,
    AVG(air_temperature)      AS avg_air,
    AVG(wetbulb_temperature)  AS avg_wetbulb,
    AVG(dewpoint_temperature) AS avg_dewpoint,
    AVG(sea_surface_temp)     AS avg_sst
  FROM all_records
  GROUP BY year, month
  HAVING
    avg_air      IS NOT NULL
    AND avg_wetbulb IS NOT NULL
    AND avg_dewpoint IS NOT NULL
    AND avg_sst  IS NOT NULL
),

monthly_diff AS (
  SELECT
    year,
    month,
    -- sum of absolute pair‑wise differences between the four averages
    ABS(avg_air     - avg_wetbulb) +
    ABS(avg_air     - avg_dewpoint) +
    ABS(avg_air     - avg_sst) +
    ABS(avg_wetbulb - avg_dewpoint) +
    ABS(avg_wetbulb - avg_sst) +
    ABS(avg_dewpoint- avg_sst)      AS sum_abs_diff
  FROM monthly_means
)

SELECT
  year,
  month,
  sum_abs_diff
FROM monthly_diff
ORDER BY sum_abs_diff ASC, year, month
LIMIT 3;