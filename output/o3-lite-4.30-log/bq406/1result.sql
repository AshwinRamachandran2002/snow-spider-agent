WITH years AS (
  -- Identify 2014 and use 2024 if present; otherwise fall back to the latest year available
  SELECT
    2014 AS start_year,
    COALESCE(
      MAX(IF(report_year = 2024, 2024, NULL)),
      MAX(report_year)
    ) AS end_year
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall'
),
base AS (
  SELECT
    report_year,
    race_asian           AS asian,
    race_black           AS black,
    race_hispanic_latinx AS latinx,
    race_native_american AS native_american,
    race_white           AS white,
    gender_us_women      AS us_women,
    gender_us_men        AS us_men,
    gender_global_women  AS global_women,
    gender_global_men    AS global_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`,
       years
  WHERE workforce = 'overall'
    AND report_year IN (start_year, end_year)
),
vals AS (
  SELECT
    metric,
    MAX(IF(report_year = (SELECT start_year FROM years), val, NULL)) AS v_start,
    MAX(IF(report_year = (SELECT end_year FROM years),   val, NULL)) AS v_end
  FROM base
  UNPIVOT (val FOR metric IN (
    asian, black, latinx, native_american, white,
    us_women, us_men, global_women, global_men
  ))
  GROUP BY metric
)
SELECT
  metric AS `group`,
  ROUND(SAFE_DIVIDE(v_end, v_start) - 1, 4) AS growth_rate_2014_2024
FROM vals
ORDER BY metric;