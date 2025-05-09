-- Top 10 countries by total long-term external debt (only those with a specified region)
SELECT
  d.country_code,
  s.short_name AS country_name,
  s.region,
  d.total_long_term_debt
FROM (
  SELECT
    country_code,
    SUM(value) AS total_long_term_debt
  FROM `bigquery-public-data.world_bank_intl_debt.international_debt`
  WHERE LOWER(indicator_name) LIKE '%external debt%'
    AND LOWER(indicator_name) LIKE '%long-term%'
  GROUP BY country_code
) AS d
JOIN `bigquery-public-data.world_bank_intl_debt.country_summary` AS s
  ON d.country_code = s.country_code
WHERE s.region IS NOT NULL           -- exclude aggregate groupings without a region
ORDER BY d.total_long_term_debt DESC
LIMIT 10;