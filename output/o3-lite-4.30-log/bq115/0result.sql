SELECT
  p.country_name AS country,
  ROUND(100 * SUM(g.midyear_population) / p.midyear_population, 4) AS percentage_population_under_25_2017
FROM `bigquery-public-data.census_bureau_international.midyear_population` AS p
JOIN `bigquery-public-data.census_bureau_international.midyear_population_5yr_age_sex` AS g
  ON p.country_code = g.country_code
 AND p.year        = g.year
WHERE p.year = 2017
  AND g.total_flag = 'A'      -- individual five‑year age groups
  AND g.starting_age < 25     -- ages 0‑24
GROUP BY
  p.country_name,
  p.midyear_population
ORDER BY
  percentage_population_under_25_2017 DESC,
  p.country_name
LIMIT 1;