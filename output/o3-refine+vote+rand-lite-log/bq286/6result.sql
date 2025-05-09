WITH data_2021 AS (
  SELECT
    state,
    name,
    number
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE year = 2021
    AND gender = 'F'
),
totals AS (
  SELECT
    name,
    SUM(number) AS total_number
  FROM data_2021
  GROUP BY name
),
wyoming AS (
  SELECT
    name,
    number AS wy_number
  FROM data_2021
  WHERE state = 'WY'
)
SELECT
  w.name
FROM wyoming w
JOIN totals t
USING (name)
ORDER BY SAFE_DIVIDE(w.wy_number, t.total_number) DESC, w.wy_number DESC, w.name
LIMIT 1;