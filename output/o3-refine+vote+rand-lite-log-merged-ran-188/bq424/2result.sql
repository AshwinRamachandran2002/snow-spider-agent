-- Top 10 countries (non-aggregate) by cumulative long-term external debt
SELECT
  d.country_name,
  SUM(d.value) AS total_long_term_external_debt_usd
FROM
  `bigquery-public-data.world_bank_intl_debt.international_debt` AS d
JOIN
  `bigquery-public-data.world_bank_intl_debt.country_summary`    AS c
ON
  d.country_code = c.country_code
WHERE
  LOWER(d.indicator_name) LIKE '%external debt%'   -- keep “external debt” series
  AND LOWER(d.indicator_name) LIKE '%long-term%'   -- restrict to “long-term”
  AND d.value IS NOT NULL
  AND c.region IS NOT NULL                         -- exclude aggregates
GROUP BY
  d.country_name
ORDER BY
  total_long_term_external_debt_usd DESC
LIMIT 10;