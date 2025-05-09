-- top 3 (year, month) combinations in 2010‑2014 with the smallest
-- sum of pair‑wise absolute differences among the monthly means of
-- air, wet‑bulb, dew‑point and sea‑surface temperatures
WITH data AS (
  SELECT
    2010 + CAST(_TABLE_SUFFIX AS INT64)            AS `year`,
    `month`,
    air_temperature,
    wetbulb_temperature,
    dewpoint_temperature,
    sea_surface_temp
  FROM `bigquery-public-data.noaa_icoads.icoads_core_201*`
  WHERE _TABLE_SUFFIX BETWEEN '0' AND '4'          -- keeps 2010‑2014
),
monthly_means AS (
  SELECT
    `year`,
    `month`,
    AVG(air_temperature)     AS avg_air,
    AVG(wetbulb_temperature) AS avg_wetbulb,
    AVG(dewpoint_temperature)AS avg_dewpoint,
    AVG(sea_surface_temp)    AS avg_sst
  FROM data
  GROUP BY `year`, `month`
  HAVING
    avg_air      IS NOT NULL AND
    avg_wetbulb  IS NOT NULL AND
    avg_dewpoint IS NOT NULL AND
    avg_sst      IS NOT NULL
),
diff_scores AS (
  SELECT
    `year`,
    `month`,
    -- sum of six pair‑wise absolute differences
    ( ABS(avg_air      - avg_wetbulb)  +
      ABS(avg_air      - avg_dewpoint) +
      ABS(avg_air      - avg_sst)      +
      ABS(avg_wetbulb  - avg_dewpoint) +
      ABS(avg_wetbulb  - avg_sst)      +
      ABS(avg_dewpoint - avg_sst) )    AS sum_abs_diff
  FROM monthly_means
)
SELECT
  `year`,
  `month`,
  sum_abs_diff
FROM diff_scores
ORDER BY sum_abs_diff ASC, `year`, `month`
LIMIT 3;