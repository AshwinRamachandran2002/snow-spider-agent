-- Highest median GDP (constant 2015 US$) by World Bank region
SELECT
  cs.region,
  APPROX_QUANTILES(id.value, 2)[OFFSET(1)] AS median_gdp
FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS id
JOIN `bigquery-public-data.world_bank_wdi.country_summary` AS cs
  ON id.country_code = cs.country_code
WHERE id.indicator_code = 'NY.GDP.MKTP.KD'     -- GDP (constant 2015 US$)
  AND id.value IS NOT NULL
  AND cs.region IS NOT NULL
GROUP BY cs.region
ORDER BY median_gdp DESC
LIMIT 1;