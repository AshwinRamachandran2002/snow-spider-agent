-- top 3 (year, month) between 2010‑2014 with the smallest total
-- pair‑wise absolute differences among monthly means of
-- air temperature, wet‑bulb temperature, dew‑point temperature
-- and sea‑surface temperature
WITH monthly_means AS (
  SELECT
    year,
    month,
    AVG(IF(IS_NAN(air_temperature),       NULL, air_temperature))       AS air_t,
    AVG(IF(IS_NAN(wetbulb_temperature),   NULL, wetbulb_temperature))   AS wet_t,
    AVG(IF(IS_NAN(dewpoint_temperature),  NULL, dewpoint_temperature))  AS dew_t,
    AVG(IF(IS_NAN(sea_surface_temp),      NULL, sea_surface_temp))      AS sst_t
  FROM `bigquery-public-data.noaa_icoads.icoads_core_201*`
  WHERE year BETWEEN 2010 AND 2014
  GROUP BY year, month
),
diff_scores AS (
  SELECT
    year,
    month,
    -- exclude months lacking any of the four averages
    air_t, wet_t, dew_t, sst_t,
    (ABS(air_t - wet_t) +
     ABS(air_t - dew_t) +
     ABS(air_t - sst_t) +
     ABS(wet_t - dew_t) +
     ABS(wet_t - sst_t) +
     ABS(dew_t - sst_t)) AS sum_abs_diff
  FROM monthly_means
  WHERE air_t IS NOT NULL
    AND wet_t IS NOT NULL
    AND dew_t IS NOT NULL
    AND sst_t IS NOT NULL
)
SELECT
  year,
  month,
  sum_abs_diff
FROM diff_scores
ORDER BY sum_abs_diff ASC
LIMIT 3;