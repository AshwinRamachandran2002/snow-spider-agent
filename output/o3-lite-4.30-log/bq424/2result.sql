SELECT
  d.country_name AS country,
  ROUND(SUM(d.value), 4) AS long_term_external_debt_usd
FROM
  `bigquery-public-data.world_bank_wdi.indicators_data` AS d
JOIN
  `bigquery-public-data.world_bank_wdi.country_summary` AS cs
ON
  d.country_code = cs.country_code
WHERE
  d.indicator_code = 'DT.DOD.DLXF.CD'     -- long‑term external debt (current US$)
  AND d.value IS NOT NULL
  AND cs.region IS NOT NULL               -- exclude entries without a specified region
  AND cs.region <> ''
GROUP BY
  d.country_name
ORDER BY
  long_term_external_debt_usd DESC,
  country
LIMIT 10;