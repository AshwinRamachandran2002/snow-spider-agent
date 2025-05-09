WITH under25 AS (
  SELECT
    country_code,
    country_name,
    SUM(midyear_population) AS pop_under25
  FROM
    `bigquery-public-data.census_bureau_international.midyear_population_5yr_age_sex`
  WHERE
    year = 2017
    AND total_flag = 'A'                 -- individual 5‑year age groups
    AND age_group_indicator = '-'        -- closed 5‑year groups
    AND starting_age < 25                -- groups 0‑4, 5‑9, 10‑14, 15‑19, 20‑24
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
    year = 2017
)
SELECT
  u.country_name,
  u.pop_under25 / t.total_pop * 100 AS pct_population_under_25
FROM
  under25 AS u
JOIN
  total_pop AS t
USING (country_code)
ORDER BY
  pct_population_under_25 DESC,
  u.country_name
LIMIT 1;