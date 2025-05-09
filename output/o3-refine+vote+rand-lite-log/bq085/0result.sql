WITH cases AS (
  SELECT
    -- harmonize country names to match World Bank data
    CASE
      WHEN country_region = 'US'   THEN 'United States'
      WHEN country_region = 'Iran' THEN 'Iran, Islamic Rep.'
      ELSE country_region
    END                                   AS country,
    SUM(confirmed)                        AS confirmed_cases
  FROM `bigquery-public-data.covid19_jhu_csse.summary`
  WHERE date = '2020-04-20'
    AND country_region IN ('US','France','China','Italy','Spain','Germany','Iran')
  GROUP BY country
),
population AS (
  SELECT
    country_name          AS country,
    value                 AS population_2020
  FROM `bigquery-public-data.world_bank_wdi.indicators_data`
  WHERE indicator_code = 'SP.POP.TOTL'      -- total population
    AND year           = 2020
    AND country_name   IN ('United States','France','China','Italy','Spain','Germany','Iran, Islamic Rep.')
)

SELECT
  c.country,
  c.confirmed_cases,
  p.population_2020,
  ROUND(c.confirmed_cases / p.population_2020 * 100000, 2) AS cases_per_100k
FROM cases      AS c
JOIN population AS p
USING (country)
ORDER BY c.country;