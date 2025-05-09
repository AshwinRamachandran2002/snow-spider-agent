WITH wy AS (
  SELECT
    name,
    SUM(number) AS wy_female
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE state = 'WY'
    AND gender = 'F'
    AND year = 2021
  GROUP BY name
),
us AS (
  SELECT
    name,
    SUM(number) AS total_female_us
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE gender = 'F'
    AND year = 2021
  GROUP BY name
)
SELECT
  wy.name
FROM wy
JOIN us USING (name)
ORDER BY SAFE_DIVIDE(wy_female, total_female_us) DESC
LIMIT 1;