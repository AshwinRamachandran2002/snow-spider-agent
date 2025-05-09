-- Top 10 countries (with a defined World Bank region) by their most-recent
-- long-term external debt stocks (current US$)

WITH latest_per_country AS (
  SELECT
    country_code,
    country_name,
    value AS debt_usd,
    ROW_NUMBER() OVER (PARTITION BY country_code ORDER BY year DESC) AS rn
  FROM `bigquery-public-data.world_bank_wdi.indicators_data`
  WHERE indicator_code = 'DT.DOD.DLXF.CD'          -- External debt stocks, long-term (current US$)
    AND value IS NOT NULL
    AND NOT IS_NAN(value)
)
SELECT
  l.country_name AS country,
  c.region,
  l.debt_usd     AS long_term_external_debt_usd
FROM latest_per_country AS l
JOIN `bigquery-public-data.world_bank_wdi.country_summary` AS c
  ON c.country_code = l.country_code
WHERE l.rn = 1                 -- keep the latest-year record per country
  AND c.region IS NOT NULL
  AND c.region <> ''
ORDER BY long_term_external_debt_usd DESC
LIMIT 10;