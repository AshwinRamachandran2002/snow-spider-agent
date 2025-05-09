-- Top 10 countries by cumulative long-term external debt (current US$),
-- excluding aggregates or countries without a defined World Bank region.
WITH debt_totals AS (
  SELECT
    country_code,
    SUM(value) AS total_long_term_debt
  FROM `bigquery-public-data.world_bank_intl_debt.international_debt`
  WHERE indicator_code = 'DT.DOD.DLXF.CD'          -- long-term external debt
  GROUP BY country_code
)
SELECT
  cs.short_name AS country,
  dt.total_long_term_debt
FROM debt_totals AS dt
JOIN `bigquery-public-data.world_bank_intl_debt.country_summary` AS cs
  ON cs.country_code = dt.country_code
WHERE cs.region IS NOT NULL                       -- drop entries without region
ORDER BY dt.total_long_term_debt DESC
LIMIT 10;