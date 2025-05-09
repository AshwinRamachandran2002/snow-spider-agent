SELECT
  country_name,
  country_code,
  100.0 * SUM(CASE 
                WHEN total_flag = 'A'          -- 5-year age-group records
                     AND age_group_indicator = '-'
                     AND starting_age <= 20    -- ages 0-24
                THEN midyear_population 
              END)
        / MAX(CASE                           -- single all-ages record
                WHEN total_flag = '*'
                     AND age_group_indicator = '+'
                     AND starting_age = 0
                THEN midyear_population 
              END)           AS pct_population_under_25_2017
FROM `bigquery-public-data.census_bureau_international.midyear_population_5yr_age_sex`
WHERE year = 2017
GROUP BY country_name, country_code
ORDER BY pct_population_under_25_2017 DESC
LIMIT 1;