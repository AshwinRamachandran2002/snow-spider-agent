-- Which region has the highest median GDP (constant 2015 US$)?
WITH gdp_values AS (
  SELECT
    cs.region,
    id.value
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS id
  JOIN `bigquery-public-data.world_bank_wdi.country_summary` AS cs
    ON cs.country_code = id.country_code
  WHERE id.indicator_code = 'NY.GDP.MKTP.KD'   -- GDP (constant 2015 US$)
    AND id.value IS NOT NULL
    AND cs.region IS NOT NULL
)

SELECT
  region AS highest_median_gdp_region,
  PERCENTILE_CONT(value, 0.5) OVER (PARTITION BY region) AS median_gdp_const_2015_usd
FROM gdp_values
QUALIFY ROW_NUMBER() OVER (PARTITION BY region) = 1   -- one row per region
ORDER BY median_gdp_const_2015_usd DESC
LIMIT 1;