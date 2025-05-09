WITH confirmed AS (
  SELECT
    country_region AS country,
    SUM(confirmed) AS confirmed_cases
  FROM `bigquery-public-data.covid19_jhu_csse.summary`
  WHERE date = '2020-04-20'
    AND country_region IN ('US','France','China','Italy','Spain','Germany','Iran')
  GROUP BY country_region
),
population AS (
  SELECT
    CASE country_code
      WHEN 'USA' THEN 'US'
      WHEN 'FRA' THEN 'France'
      WHEN 'CHN' THEN 'China'
      WHEN 'ITA' THEN 'Italy'
      WHEN 'ESP' THEN 'Spain'
      WHEN 'DEU' THEN 'Germany'
      WHEN 'IRN' THEN 'Iran'
    END AS country,
    SUM(value) AS population_2020
  FROM `bigquery-public-data.world_bank_wdi.indicators_data`
  WHERE indicator_code = 'SP.POP.TOTL'
    AND year = 2020
    AND country_code IN ('USA','FRA','CHN','ITA','ESP','DEU','IRN')
  GROUP BY country
)
SELECT
  c.country,
  c.confirmed_cases,
  p.population_2020,
  ROUND(c.confirmed_cases / p.population_2020 * 100000, 4) AS cases_per_100k
FROM confirmed AS c
JOIN population AS p
USING (country)
ORDER BY cases_per_100k DESC;