-- COVID‑19 confirmed cases (20 Apr 2020) vs 2020 population  
-- for US, France, China, Italy, Spain, Germany, and Iran
WITH countries AS (
  SELECT *
  FROM UNNEST([
    STRUCT('US'    AS jhu_country, 'USA' AS wb_code, 'United States' AS country),
    ('France',     'FRA', 'France'),
    ('China',      'CHN', 'China'),
    ('Italy',      'ITA', 'Italy'),
    ('Spain',      'ESP', 'Spain'),
    ('Germany',    'DEU', 'Germany'),
    ('Iran',       'IRN', 'Iran')
  ])
),  
cases AS (   -- total confirmed cases on 2020‑04‑20
  SELECT
    c.wb_code,
    SUM(s.confirmed) AS confirmed_cases
  FROM `bigquery-public-data.covid19_jhu_csse.summary` s
  JOIN countries c
    ON s.country_region = c.jhu_country
  WHERE s.date = '2020-04-20'
  GROUP BY c.wb_code
),  
pop AS (     -- 2020 total population
  SELECT
    country_code AS wb_code,
    value        AS population_2020
  FROM `bigquery-public-data.world_bank_wdi.indicators_data`
  WHERE indicator_code = 'SP.POP.TOTL'  -- total population
    AND year = 2020
    AND country_code IN ('USA','FRA','CHN','ITA','ESP','DEU','IRN')
)  
SELECT
  c.country,
  ca.confirmed_cases,
  pop.population_2020,
  ROUND(ca.confirmed_cases / pop.population_2020 * 100000, 4) AS cases_per_100k
FROM cases ca
JOIN pop       USING (wb_code)
JOIN countries c USING (wb_code)
ORDER BY c.country;