/* Top 10 countries by latest reported long‑term external debt
   (current US$), omitting economies that have no World Bank region */

WITH ranked_debt AS (
  SELECT
    country_code,
    country_name,
    year,
    value AS debt_usd,
    ROW_NUMBER() OVER (PARTITION BY country_code ORDER BY year DESC) AS rn
  FROM `bigquery-public-data.world_bank_wdi.indicators_data`
  WHERE indicator_code = 'DT.DOD.DLXF.CD'          -- Long‑term external debt stocks (current US$)
    AND value IS NOT NULL
)

SELECT
  rd.country_name,
  rd.country_code,
  cs.region,
  rd.year  AS latest_year,
  rd.debt_usd AS long_term_external_debt_usd
FROM ranked_debt AS rd
JOIN `bigquery-public-data.world_bank_wdi.country_summary` AS cs
  ON rd.country_code = cs.country_code
WHERE rd.rn = 1                                    -- keep most recent year per country
  AND cs.region IS NOT NULL                        -- exclude aggregates / unspecified regions
ORDER BY rd.debt_usd DESC
LIMIT 10;