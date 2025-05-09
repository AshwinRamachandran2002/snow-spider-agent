-- Region with the highest median GDP (constant 2015 US$)
WITH gdp AS (
  SELECT
    cs.region,
    id.value
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS id
  JOIN `bigquery-public-data.world_bank_wdi.country_summary` AS cs
    ON id.country_code = cs.country_code
  WHERE id.indicator_code = 'NY.GDP.MKTP.KD'      -- GDP (constant 2015 US$)
    AND id.value IS NOT NULL
    AND cs.region IS NOT NULL                     -- exclude aggregates and undefined regions
),
region_median AS (
  SELECT
    region,
    APPROX_QUANTILES(value, 2)[OFFSET(1)] AS median_gdp_2015_usd
  FROM gdp
  GROUP BY region
)
SELECT
  region,
  median_gdp_2015_usd
FROM region_median
ORDER BY median_gdp_2015_usd DESC
LIMIT 1;