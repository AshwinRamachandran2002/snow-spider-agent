WITH under_20 AS (
  SELECT
    country_code,
    country_name,
    SUM(midyear_population) AS pop_under20
  FROM
    `bigquery-public-data.census_bureau_international.midyear_population_5yr_age_sex`
  WHERE
    year = 2020
    AND total_flag = 'A'          -- 5‑year age‑group rows
    AND starting_age < 20         -- ages 0‑19
  GROUP BY
    country_code,
    country_name
),
total_pop AS (
  SELECT
    country_code,
    midyear_population AS total_pop
  FROM
    `bigquery-public-data.census_bureau_international.midyear_population`
  WHERE
    year = 2020
)
SELECT
  u.country_name                                   AS country,
  u.pop_under20                                    AS total_population_under_20,
  t.total_pop                                      AS total_midyear_population,
  ROUND(100 * u.pop_under20 / t.total_pop, 4)      AS percent_under_20
FROM
  under_20 u
JOIN
  total_pop t
USING (country_code)
ORDER BY
  percent_under_20 DESC,
  country ASC
LIMIT 10;