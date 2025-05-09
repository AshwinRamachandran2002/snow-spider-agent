-- Top 3 (year, month) during 2010‑2014 with the smallest total
-- pair‑wise absolute differences among the monthly means of
-- air temperature, wet‑bulb temperature, dew‑point temperature
-- and sea‑surface temperature.
WITH monthly_means AS (
  SELECT
    year,
    month,
    AVG(CASE WHEN air_temperature BETWEEN -100 AND 100 THEN air_temperature END) AS avg_air,
    AVG(CASE WHEN wetbulb_temperature BETWEEN -100 AND 100 THEN wetbulb_temperature END) AS avg_wb,
    AVG(CASE WHEN dewpoint_temperature BETWEEN -100 AND 100 THEN dewpoint_temperature END) AS avg_dew,
    AVG(CASE WHEN sea_surface_temp  BETWEEN -100 AND 100 THEN sea_surface_temp  END) AS avg_sst
  FROM
    `bigquery-public-data.noaa_icoads.icoads_core_201*`
  WHERE
    _TABLE_SUFFIX IN ('0','1','2','3','4')        -- keeps 2010‑2014 tables
    AND year BETWEEN 2010 AND 2014
  GROUP BY
    year, month
)
SELECT
  year,
  month,
  -- sum of the six pair‑wise absolute differences
  ABS(avg_air - avg_wb)  + ABS(avg_air - avg_dew) + ABS(avg_air - avg_sst) +
  ABS(avg_wb  - avg_dew) + ABS(avg_wb  - avg_sst) + ABS(avg_dew - avg_sst)
    AS sum_abs_diffs
FROM
  monthly_means
WHERE
  avg_air IS NOT NULL
  AND avg_wb  IS NOT NULL
  AND avg_dew IS NOT NULL
  AND avg_sst IS NOT NULL
ORDER BY
  sum_abs_diffs ASC, year, month
LIMIT 3;