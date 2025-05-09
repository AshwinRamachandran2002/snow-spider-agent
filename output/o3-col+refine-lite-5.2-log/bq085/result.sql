-- Total confirmed cases on 2020‑04‑20 and rate per 100 000 inhabitants (2020 population)
WITH cases AS (
  SELECT
    CASE
      WHEN country_region = 'US'   THEN 'United States'
      WHEN country_region = 'Iran' THEN 'Iran, Islamic Rep.'
      ELSE country_region
    END                       AS country,
    SUM(confirmed)            AS total_confirmed
  FROM `bigquery-public-data.covid19_jhu_csse.summary`
  WHERE `date` = '2020-04-20'
    AND country_region IN ('US','France','China','Italy','Spain','Germany','Iran')
  GROUP BY country
),
pop AS (
  SELECT
    country_name              AS country,
    SUM(value)                AS population_2020
  FROM `bigquery-public-data.world_bank_wdi.indicators_data`
  WHERE indicator_code = 'SP.POP.TOTL'          -- total population
    AND year = 2020
    AND country_name IN ('United States','France','China','Italy',
                         'Spain','Germany','Iran, Islamic Rep.')
  GROUP BY country
)
SELECT
  c.country,
  c.total_confirmed                        AS confirmed_cases,
  p.population_2020,
  ROUND(100000.0 * c.total_confirmed / p.population_2020, 2) AS cases_per_100k
FROM cases c
JOIN pop  p USING (country)
ORDER BY cases_per_100k DESC;