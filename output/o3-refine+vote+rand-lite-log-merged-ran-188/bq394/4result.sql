/*  Top‑3 (year, month) between 2010‑2014 that have the
    smallest total of the six pair‑wise absolute differences
    among the monthly means of four temperature variables  */
WITH month_means AS (
  SELECT
    year,
    month,
    AVG(CASE WHEN NOT IS_NAN(air_temperature)      THEN air_temperature      END) AS avg_air,
    AVG(CASE WHEN NOT IS_NAN(wetbulb_temperature)  THEN wetbulb_temperature  END) AS avg_wet,
    AVG(CASE WHEN NOT IS_NAN(dewpoint_temperature) THEN dewpoint_temperature END) AS avg_dew,
    AVG(CASE WHEN NOT IS_NAN(sea_surface_temp)     THEN sea_surface_temp     END) AS avg_sst
  FROM
    `bigquery-public-data.noaa_icoads.icoads_core_20*`
  WHERE
    year BETWEEN 2010 AND 2014
  GROUP BY
    year,
    month
  HAVING
    avg_air IS NOT NULL
    AND avg_wet IS NOT NULL
    AND avg_dew IS NOT NULL
    AND avg_sst IS NOT NULL
),
month_scores AS (
  SELECT
    year,
    month,
    (ABS(avg_air - avg_wet) +
     ABS(avg_air - avg_dew) +
     ABS(avg_air - avg_sst) +
     ABS(avg_wet - avg_dew) +
     ABS(avg_wet - avg_sst) +
     ABS(avg_dew - avg_sst)) AS sum_abs_diff
  FROM month_means
)
SELECT
  year,
  month,
  ROUND(sum_abs_diff, 4) AS sum_abs_diff
FROM
  month_scores
ORDER BY
  sum_abs_diff ASC,
  year,
  month
LIMIT 3;