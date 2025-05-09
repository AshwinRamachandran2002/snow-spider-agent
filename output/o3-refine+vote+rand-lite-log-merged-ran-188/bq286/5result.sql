WITH national_totals AS (
  SELECT
    name,
    SUM(number) AS total_female_2021
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE gender = 'F'
    AND year = 2021
  GROUP BY name
),
wyoming_counts AS (
  SELECT
    name,
    SUM(number) AS wy_female_2021
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE gender = 'F'
    AND year = 2021
    AND state = 'WY'
  GROUP BY name
),
proportions AS (
  SELECT
    w.name,
    SAFE_DIVIDE(w.wy_female_2021, n.total_female_2021) AS proportion
  FROM wyoming_counts w
  JOIN national_totals n USING (name)
)
SELECT name
FROM proportions
ORDER BY proportion DESC, name
LIMIT 1;