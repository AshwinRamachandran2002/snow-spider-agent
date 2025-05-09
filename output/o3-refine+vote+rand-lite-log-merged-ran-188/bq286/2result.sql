WITH wy_female AS (
  SELECT
    name,
    SUM(number) AS wy_count
  FROM
    `bigquery-public-data.usa_names.usa_1910_current`
  WHERE
    state = 'WY'
    AND gender = 'F'
    AND year = 2021
  GROUP BY
    name
),
total_female AS (
  SELECT
    name,
    SUM(number) AS total_count
  FROM
    `bigquery-public-data.usa_names.usa_1910_current`
  WHERE
    gender = 'F'
    AND year = 2021
  GROUP BY
    name
),
proportions AS (
  SELECT
    w.name,
    w.wy_count,
    t.total_count,
    SAFE_DIVIDE(w.wy_count, t.total_count) AS proportion
  FROM
    wy_female w
  JOIN
    total_female t
  USING (name)
)
SELECT
  name
FROM
  proportions
ORDER BY
  proportion DESC,
  name
LIMIT 1;