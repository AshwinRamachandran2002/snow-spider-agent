WITH
-- 1. Confirmed COVID‑19 cases on 20‑Apr‑2020
cases AS (
  SELECT
    country_region                                         AS country_key,
    SUM(confirmed)                                         AS confirmed_cases
  FROM `bigquery-public-data.covid19_jhu_csse.summary`
  WHERE date = '2020-04-20'
    AND country_region IN ('US','France','China','Italy','Spain','Germany','Iran')
  GROUP BY country_region
),

-- 2. 2020 total population (World Bank – indicator “SP.POP.TOTL”)
pop AS (
  SELECT
    -- harmonise names to JHU keys
    CASE country_name
         WHEN 'United States'        THEN 'US'
         WHEN 'Iran, Islamic Rep.'   THEN 'Iran'
         ELSE country_name
    END                                              AS country_key,
    value                                            AS population_2020
  FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE indicator_code = 'SP.POP.TOTL'
    AND year = 2020
    AND country_name IN ('United States','France','China','Italy','Spain','Germany','Iran, Islamic Rep.')
)

-- 3. Combine and calculate cases per 100,000 residents
SELECT
  c.country_key                               AS country,
  c.confirmed_cases,
  p.population_2020                           AS population_2020,
  ROUND( (c.confirmed_cases / p.population_2020) * 100000, 2) AS cases_per_100k
FROM cases c
JOIN pop  p USING (country_key)
ORDER BY country;