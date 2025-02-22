-- Task: Which top 3 countries had the highest net migration in 2017? And what are their migration rates?
SELECT
    country_name,
    net_migration
FROM
    `bigquery-public-data.census_bureau_international.birth_death_growth_rates`
WHERE
    year = 2017
ORDER BY
    net_migration DESC
LIMIT 3