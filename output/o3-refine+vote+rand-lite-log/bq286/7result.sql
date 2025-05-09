WITH wy_counts AS (
  SELECT
    name,
    number AS wy_number
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE state = 'WY'
    AND gender = 'F'
    AND year = 2021
),
total_counts AS (
  SELECT
    name,
    SUM(number) AS total_number
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE gender = 'F'
    AND year = 2021
  GROUP BY name
),
proportions AS (
  SELECT
    w.name,
    SAFE_DIVIDE(w.wy_number, t.total_number) AS proportion
  FROM wy_counts w
  JOIN total_counts t USING (name)
)
SELECT name
FROM proportions
ORDER BY proportion DESC, name
LIMIT 1;