WITH wyoming AS (
  SELECT
    name,
    SUM(number) AS wy_total
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE state = 'WY'
    AND gender = 'F'
    AND year = 2021
  GROUP BY name
),
us_totals AS (
  SELECT
    name,
    SUM(number) AS us_total
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE gender = 'F'
    AND year = 2021
  GROUP BY name
)

SELECT
  w.name
FROM wyoming w
JOIN us_totals u
  USING (name)
ORDER BY
  w.wy_total / u.us_total DESC,
  w.name
LIMIT 1;