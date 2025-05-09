-- Top 3 year‑months (2010‑2014) with the smallest total pair‑wise
-- absolute differences among the monthly means of
-- air temperature, wet‑bulb temperature, dew‑point temperature,
-- and sea‑surface temperature
WITH monthly_means AS (
  SELECT
    year,
    month,
    AVG(air_temperature)      AS avg_air,
    AVG(wetbulb_temperature)  AS avg_wet,
    AVG(dewpoint_temperature) AS avg_dew,
    AVG(sea_surface_temp)     AS avg_sst
  FROM
    `bigquery-public-data.noaa_icoads.icoads_core_201*`
  WHERE
        _TABLE_SUFFIX IN ('0','1','2','3','4')      -- tables 2010‑2014
    AND year BETWEEN 2010 AND 2014                  -- extra safety‑check
  GROUP BY
    year,
    month
),
diffs AS (
  SELECT
    year,
    month,
    -- sum of the six pair‑wise absolute differences
    ABS(avg_air - avg_wet) +
    ABS(avg_air - avg_dew) +
    ABS(avg_air - avg_sst) +
    ABS(avg_wet - avg_dew) +
    ABS(avg_wet - avg_sst) +
    ABS(avg_dew - avg_sst)  AS sum_abs_diff
  FROM
    monthly_means
  WHERE
        avg_air IS NOT NULL
    AND avg_wet IS NOT NULL
    AND avg_dew IS NOT NULL
    AND avg_sst IS NOT NULL     -- ensure all means exist
)
SELECT
  year,
  month,
  ROUND(sum_abs_diff, 4) AS sum_of_abs_differences
FROM
  diffs
ORDER BY
  sum_abs_diff ASC
LIMIT 3;