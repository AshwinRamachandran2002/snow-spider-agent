WITH wy_counts AS (
  SELECT
    `name`,
    SUM(`number`) AS wy_total
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE `state` = 'WY'
    AND `gender` = 'F'
    AND `year` = 2021
  GROUP BY `name`
),
us_counts AS (
  SELECT
    `name`,
    SUM(`number`) AS us_total
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE `gender` = 'F'
    AND `year` = 2021
  GROUP BY `name`
)
SELECT
  wy_counts.`name`
FROM wy_counts
JOIN us_counts USING (`name`)
ORDER BY SAFE_DIVIDE(wy_counts.wy_total, us_counts.us_total) DESC
LIMIT 1;