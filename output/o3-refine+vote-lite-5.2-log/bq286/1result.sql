WITH year_data AS (
  SELECT
    state,
    name,
    number
  FROM
    `bigquery-public-data.usa_names.usa_1910_current`
  WHERE
    year = 2021
    AND gender = 'F'
),
totals AS (
  SELECT
    name,
    SUM(number) AS total_count,
    SUM(CASE WHEN state = 'WY' THEN number ELSE 0 END) AS wy_count
  FROM
    year_data
  GROUP BY
    name
),
proportions AS (
  SELECT
    name,
    SAFE_DIVIDE(wy_count, total_count) AS wy_proportion
  FROM
    totals
  WHERE
    wy_count > 0
)
SELECT
  name
FROM
  proportions
ORDER BY
  wy_proportion DESC,
  name ASC
LIMIT 1;