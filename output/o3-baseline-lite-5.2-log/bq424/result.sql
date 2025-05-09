WITH latest_debt AS (
  SELECT
    id.country_code,
    id.country_name,
    id.value AS long_term_external_debt_usd,
    ROW_NUMBER() OVER (PARTITION BY id.country_code ORDER BY id.year DESC) AS rn
  FROM
    `bigquery-public-data.world_bank_wdi.indicators_data` AS id
  WHERE
    id.indicator_code = 'DT.DOD.DLXF.CD'      -- External debt stocks, long‑term (current US$)
    AND id.value IS NOT NULL
    AND NOT IS_NAN(id.value)
)
SELECT
  cs.short_name AS country_name,
  ld.long_term_external_debt_usd
FROM
  latest_debt AS ld
JOIN
  `bigquery-public-data.world_bank_wdi.country_summary` AS cs
ON
  ld.country_code = cs.country_code
WHERE
  ld.rn = 1                      -- most recent year per country
  AND cs.region IS NOT NULL      -- exclude countries without a specified region
  AND cs.region <> ''
ORDER BY
  ld.long_term_external_debt_usd DESC
LIMIT
  10;