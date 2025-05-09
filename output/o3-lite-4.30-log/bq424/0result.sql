SELECT
  cs.short_name AS country,
  ROUND(SUM(id.value), 4) AS long_term_external_debt_usd
FROM
  `bigquery-public-data.world_bank_wdi.indicators_data` AS id
JOIN
  `bigquery-public-data.world_bank_wdi.country_summary` AS cs
ON
  id.country_code = cs.country_code
WHERE
  id.indicator_code = 'DT.DOD.DLXF.CD'      -- External debt stocks, long‑term (current US$)
  AND cs.region IS NOT NULL                 -- exclude entities without a specified region
  AND id.value IS NOT NULL
GROUP BY
  country
ORDER BY
  long_term_external_debt_usd DESC,
  country
LIMIT 10;