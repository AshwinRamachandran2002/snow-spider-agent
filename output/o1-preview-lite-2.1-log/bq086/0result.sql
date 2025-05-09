WITH covid_cases AS (
  SELECT 
    iso_3166_1_alpha_3 AS country_code,
    country_name,
    MAX(cumulative_confirmed) AS cumulative_confirmed
  FROM 
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE 
    date = '2020-06-30' 
    AND cumulative_confirmed IS NOT NULL
    AND iso_3166_1_alpha_3 IS NOT NULL
    AND aggregation_level = 1
  GROUP BY 
    iso_3166_1_alpha_3, country_name
),
population AS (
  SELECT
    country_code,
    MAX(value) AS population
  FROM
    `bigquery-public-data.world_bank_wdi.indicators_data`
  WHERE
    indicator_code = 'SP.POP.TOTL' 
    AND year = 2019 
    AND value IS NOT NULL
  GROUP BY
    country_code
)
SELECT
  covid_cases.country_name AS Country_name,
  ROUND((covid_cases.cumulative_confirmed / population.population) * 100, 4) AS COVID_confirmed_percentage
FROM
  covid_cases
JOIN
  population
ON
  covid_cases.country_code = population.country_code
ORDER BY
  COVID_confirmed_percentage DESC;