WITH gdp_per_country_year AS (
  SELECT
    cs.region,
    id.value
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS id
  JOIN `bigquery-public-data.world_bank_wdi.country_summary` AS cs
    ON id.country_code = cs.country_code
  WHERE id.indicator_code = 'NY.GDP.MKTP.KD'         -- GDP (constant 2015 US$)
    AND id.value IS NOT NULL
    AND cs.region IS NOT NULL
)

SELECT
  region,
  APPROX_QUANTILES(value, 2)[OFFSET(1)] AS median_gdp_constant_2015_usd
FROM gdp_per_country_year
GROUP BY region
ORDER BY median_gdp_constant_2015_usd DESC
LIMIT 1;