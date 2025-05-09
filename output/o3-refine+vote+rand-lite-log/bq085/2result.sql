WITH country_map AS (
  SELECT 'US'      AS summary_country, 'United States'        AS wb_country UNION ALL
  SELECT 'France'  AS summary_country, 'France'               AS wb_country UNION ALL
  SELECT 'China'   AS summary_country, 'China'                AS wb_country UNION ALL
  SELECT 'Italy'   AS summary_country, 'Italy'                AS wb_country UNION ALL
  SELECT 'Spain'   AS summary_country, 'Spain'                AS wb_country UNION ALL
  SELECT 'Germany' AS summary_country, 'Germany'              AS wb_country UNION ALL
  SELECT 'Iran'    AS summary_country, 'Iran, Islamic Rep.'   AS wb_country
),

-- Confirmed cases on 2020‑04‑20
cases AS (
  SELECT
    cm.summary_country AS country,
    SUM(s.confirmed)   AS total_cases
  FROM `bigquery-public-data.covid19_jhu_csse.summary` AS s
  JOIN country_map cm
    ON s.country_region = cm.summary_country
  WHERE s.date = '2020-04-20'
  GROUP BY cm.summary_country
),

-- Population (prefer 2020, fallback to 2019) from WDI indicator SP.POP.TOTL
pop AS (
  SELECT
    cm.summary_country AS country,
    COALESCE(
      MAX(CASE WHEN id.year = 2020 THEN id.value END),
      MAX(CASE WHEN id.year = 2019 THEN id.value END)
    ) AS population
  FROM country_map cm
  LEFT JOIN `bigquery-public-data.world_bank_wdi.indicators_data` AS id
    ON id.country_name = cm.wb_country
   AND id.indicator_code = 'SP.POP.TOTL'
  GROUP BY cm.summary_country
)

SELECT
  c.country,
  c.total_cases,
  p.population,
  ROUND(c.total_cases * 100000.0 / p.population, 2) AS cases_per_100k
FROM cases c
JOIN pop   p USING (country)
ORDER BY country;