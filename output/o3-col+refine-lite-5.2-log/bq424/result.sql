-- Top‑10 countries by their most recent (non‑NULL) value of
-- “External debt stocks, long‑term (current US$)”,
-- excluding countries that lack a World Bank region
WITH latest AS (
  SELECT
    country_code,
    MAX(year) AS latest_year
  FROM
    `bigquery-public-data.world_bank_wdi.indicators_data`
  WHERE
    indicator_code = 'DT.DOD.DLXF.CD'      -- long‑term external debt
    AND value IS NOT NULL
  GROUP BY
    country_code
)
SELECT
  cs.short_name                               AS country,
  cs.region,
  d.year,
  d.value                                     AS long_term_external_debt_usd
FROM
  latest AS l
JOIN
  `bigquery-public-data.world_bank_wdi.indicators_data` AS d
ON
  d.country_code   = l.country_code
  AND d.year       = l.latest_year
  AND d.indicator_code = 'DT.DOD.DLXF.CD'
JOIN
  `bigquery-public-data.world_bank_wdi.country_summary` AS cs
ON
  cs.country_code = d.country_code
WHERE
  cs.region IS NOT NULL                       -- exclude “regionless” entries
ORDER BY
  d.value DESC
LIMIT 10;