WITH long_term_debt AS (
  SELECT
    country_code,
    SUM(value) AS total_long_term_debt_usd
  FROM
    `bigquery-public-data.world_bank_wdi.indicators_data`
  WHERE
    indicator_code = 'DT.DOD.DLXF.CD'          -- External debt stocks, long‑term (current US$)
    AND value IS NOT NULL
  GROUP BY
    country_code
)
SELECT
  cs.short_name AS country,
  ltd.total_long_term_debt_usd
FROM
  long_term_debt ltd
JOIN
  `bigquery-public-data.world_bank_wdi.country_summary` cs
ON
  ltd.country_code = cs.country_code
WHERE
  cs.region IS NOT NULL                        -- exclude entries without a specified region
  AND TRIM(cs.region) <> ''
ORDER BY
  ltd.total_long_term_debt_usd DESC,
  country
LIMIT 10;