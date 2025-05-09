WITH country_map AS (
  -- Map country names used in the JHU table to the names used in the World Bank tables
  SELECT *
  FROM UNNEST([
    STRUCT('US'      AS jhu_country, 'United States'      AS wb_country),
    STRUCT('France'  AS jhu_country, 'France'             AS wb_country),
    STRUCT('China'   AS jhu_country, 'China'              AS wb_country),
    STRUCT('Italy'   AS jhu_country, 'Italy'              AS wb_country),
    STRUCT('Spain'   AS jhu_country, 'Spain'              AS wb_country),
    STRUCT('Germany' AS jhu_country, 'Germany'            AS wb_country),
    STRUCT('Iran'    AS jhu_country, 'Iran, Islamic Rep.' AS wb_country)
  ])
),

-- Confirmed COVID‑19 cases on 2020‑04‑20
cases AS (
  SELECT
    country_region              AS jhu_country,
    SUM(confirmed)              AS confirmed_cases
  FROM
    `bigquery-public-data.covid19_jhu_csse.summary`
  WHERE
    date = '2020-04-20'
    AND country_region IN (SELECT jhu_country FROM country_map)
  GROUP BY
    country_region
),

-- 2020 population (World Bank, total population indicator)
population AS (
  SELECT
    country_name                AS wb_country,
    SUM(value)                  AS population_2020
  FROM
    `bigquery-public-data.world_bank_wdi.indicators_data`
  WHERE
    indicator_code = 'SP.POP.TOTL'
    AND year = 2020
    AND country_name IN (SELECT wb_country FROM country_map)
  GROUP BY
    country_name
)

SELECT
  m.wb_country                                   AS country,
  c.confirmed_cases,
  c.confirmed_cases / p.population_2020 * 100000 AS cases_per_100k
FROM
  country_map AS m
JOIN
  cases      AS c ON m.jhu_country = c.jhu_country
JOIN
  population AS p ON m.wb_country  = p.wb_country
ORDER BY
  country;