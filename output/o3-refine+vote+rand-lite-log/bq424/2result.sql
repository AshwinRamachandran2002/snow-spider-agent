SELECT
  d.country_name                          AS country,
  SUM(d.value)                            AS total_long_term_external_debt_usd
FROM
  `bigquery-public-data.world_bank_intl_debt.international_debt` AS d
JOIN
  `bigquery-public-data.world_bank_intl_debt.country_summary`     AS c
ON  d.country_code = c.country_code
WHERE
  d.indicator_code = 'DT.DOD.DLXF.CD'          -- Long‑term external debt (DOD, current US$)
  AND c.region IS NOT NULL                     -- exclude economies without a specified region
GROUP BY
  country
ORDER BY
  total_long_term_external_debt_usd DESC,
  country
LIMIT 10;