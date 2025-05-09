WITH national AS (
  -- total female births for each name across all states in 2021
  SELECT
    name,
    SUM(number) AS total_across_states
  FROM
    `bigquery-public-data.usa_names.usa_1910_current`
  WHERE
    gender = 'F'
    AND year = 2021
  GROUP BY
    name
),
wyoming AS (
  -- female births for each name in Wyoming in 2021
  SELECT
    name,
    SUM(number) AS wyoming_total
  FROM
    `bigquery-public-data.usa_names.usa_1910_current`
  WHERE
    gender = 'F'
    AND year = 2021
    AND state = 'WY'
  GROUP BY
    name
)
SELECT
  w.name
FROM
  wyoming AS w
JOIN
  national AS n
USING (name)
ORDER BY
  SAFE_DIVIDE(w.wyoming_total, n.total_across_states) DESC,  -- highest proportion first
  w.name                                                    -- tie‑breaker
LIMIT 1;