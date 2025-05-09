WITH countries AS (
  -- mapping between JHU country names and World Bank ISO‑3 codes
  SELECT * FROM UNNEST([
    STRUCT('US'     AS jhu_name, 'USA' AS iso3 , 'United States' AS country),
    ('France'       , 'FRA', 'France'        ),
    ('China'        , 'CHN', 'China'         ),
    ('Italy'        , 'ITA', 'Italy'         ),
    ('Spain'        , 'ESP', 'Spain'         ),
    ('Germany'      , 'DEU', 'Germany'       ),
    ('Iran'         , 'IRN', 'Iran')
  ])
),
-- total confirmed cases on 2020‑04‑20
confirmed AS (
  SELECT
    c.iso3,
    SUM(s.confirmed) AS confirmed_cases
  FROM `bigquery-public-data.covid19_jhu_csse.summary` s
  JOIN countries c
    ON s.country_region = c.jhu_name
  WHERE s.date = '2020-04-20'
  GROUP BY c.iso3
),
-- 2020 population (total) from World Bank WDI
population AS (
  SELECT
    country_code AS iso3,
    SUM(value)   AS pop_2020
  FROM `bigquery-public-data.world_bank_wdi.indicators_data`
  WHERE indicator_code = 'SP.POP.TOTL'
    AND year = 2020
    AND country_code IN ('USA','FRA','CHN','ITA','ESP','DEU','IRN')
  GROUP BY country_code
)
SELECT
  c.country,
  conf.confirmed_cases,
  pop.pop_2020,
  ROUND(SAFE_DIVIDE(conf.confirmed_cases, pop.pop_2020) * 100000, 4) AS cases_per_100k
FROM countries c
JOIN confirmed  conf ON c.iso3 = conf.iso3
JOIN population pop  ON c.iso3 = pop.iso3
ORDER BY c.country;