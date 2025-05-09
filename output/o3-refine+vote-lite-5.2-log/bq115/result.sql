WITH under25 AS (
  SELECT
    country_code,
    SUM(midyear_population) AS pop_under25
  FROM
    `bigquery-public-data.census_bureau_international.midyear_population_5yr_age_sex`
  WHERE
    year = 2017
    AND total_flag = 'A'            -- individual 5‑year age‑group rows
    AND age_group_indicator = '-'   -- 5‑year closed age groups
    AND starting_age < 25           -- 0‑4 … 20‑24
  GROUP BY
    country_code
),
tot AS (
  SELECT
    country_code,
    country_name,
    midyear_population AS total_pop
  FROM
    `bigquery-public-data.census_bureau_international.midyear_population`
  WHERE
    year = 2017
)
SELECT
  t.country_name,
  ROUND(u.pop_under25 * 100.0 / t.total_pop, 4) AS pct_population_under_25
FROM
  tot t
JOIN
  under25 u
USING (country_code)
ORDER BY
  pct_population_under_25 DESC,
  t.country_name
LIMIT 1;