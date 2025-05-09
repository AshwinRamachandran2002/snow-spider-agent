WITH wy AS (
  SELECT name, SUM(number) AS wy_number
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE state = 'WY' AND gender = 'F' AND year = 2021
  GROUP BY name
),
us AS (
  SELECT name, SUM(number) AS us_number
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE gender = 'F' AND year = 2021
  GROUP BY name
)
SELECT
  wy.name,
  ROUND(wy.wy_number / us.us_number, 4) AS proportion
FROM wy
JOIN us USING (name)
ORDER BY proportion DESC, wy.name
LIMIT 1;