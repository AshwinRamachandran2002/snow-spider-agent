WITH latest_long_term_debt AS (
  SELECT
    id.country_name,
    id.country_code,
    id.year,
    id.value AS long_term_external_debt_usd
  FROM
    `bigquery-public-data.world_bank_wdi.indicators_data` AS id
  WHERE
    id.indicator_code = 'DT.DOD.DLXF.CD'      -- Long‑term external debt stock (current US$)
    AND id.value IS NOT NULL
  QUALIFY
    ROW_NUMBER() OVER (PARTITION BY id.country_code ORDER BY id.year DESC) = 1   -- keep latest year per country
)

SELECT
  ld.country_name,
  ld.country_code,
  ld.year AS latest_year,
  ld.long_term_external_debt_usd
FROM
  latest_long_term_debt AS ld
JOIN
  `bigquery-public-data.world_bank_wdi.country_summary` AS cs
ON
  ld.country_code = cs.country_code
WHERE
  cs.region IS NOT NULL                         -- exclude aggregates / unspecified regions
ORDER BY
  ld.long_term_external_debt_usd DESC
LIMIT 10;