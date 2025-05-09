WITH target_countries AS (
  SELECT 'US'    AS country_region, 'United States'        AS wb_country UNION ALL
  SELECT 'France'                 , 'France'               UNION ALL
  SELECT 'China'                  , 'China'                UNION ALL
  SELECT 'Italy'                  , 'Italy'                UNION ALL
  SELECT 'Spain'                  , 'Spain'                UNION ALL
  SELECT 'Germany'                , 'Germany'              UNION ALL
  SELECT 'Iran'                   , 'Iran, Islamic Rep.'   -- World‑Bank naming
),

-- total confirmed cases on 20‑Apr‑2020
cases AS (
  SELECT
    tc.wb_country,
    SUM(s.confirmed) AS confirmed_cases
  FROM `bigquery-public-data.covid19_jhu_csse.summary` AS s
  JOIN target_countries AS tc
    ON s.country_region = tc.country_region
  WHERE s.date = '2020-04-20'
  GROUP BY tc.wb_country
),

-- 2020 total population (World‑Bank, indicator SP.POP.TOTL)
pop AS (
  SELECT
    tc.wb_country,
    SUM(w.value) AS population_2020
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS w
  JOIN target_countries AS tc
    ON w.country_name = tc.wb_country
  WHERE w.indicator_code = 'SP.POP.TOTL'
    AND w.year = 2020
  GROUP BY tc.wb_country
)

SELECT
  c.wb_country                              AS country,
  c.confirmed_cases,
  ROUND(c.confirmed_cases / p.population_2020 * 100000, 4) AS cases_per_100k
FROM cases AS c
JOIN pop   AS p
  USING (wb_country)
ORDER BY country;