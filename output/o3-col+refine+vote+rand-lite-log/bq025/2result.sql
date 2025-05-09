-- Top 10 countries in 2020 by highest % of population under 20
WITH under20 AS (
  SELECT
    country_code,
    SUM(midyear_population) AS pop_under20
  FROM
    `bigquery-public-data.census_bureau_international.midyear_population_5yr_age_sex`
  WHERE
    year = 2020
    AND total_flag = 'A'                 -- individual 5-year age-group rows
    AND starting_age IN (0, 5, 10, 15)   -- age bands 0-19
  GROUP BY
    country_code
),
totals AS (
  SELECT
    country_code,
    country_name,
    midyear_population AS pop_total
  FROM
    `bigquery-public-data.census_bureau_international.midyear_population_5yr_age_sex`
  WHERE
    year = 2020
    AND total_flag = '*'                 -- total population rows
)
SELECT
  t.country_code,
  t.country_name,
  u.pop_under20,
  t.pop_total,
  ROUND(100 * u.pop_under20 / t.pop_total, 2) AS pct_under20
FROM
  totals AS t
JOIN
  under20 AS u
USING (country_code)
ORDER BY
  pct_under20 DESC
LIMIT 10;