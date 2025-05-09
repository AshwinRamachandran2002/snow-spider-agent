-- Region with the highest median GDP (constant 2015 US$)
WITH gdp_per_country_year AS (
  SELECT
    cs.region,
    id.value AS gdp_2015_usd
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS id
  JOIN `bigquery-public-data.world_bank_wdi.country_summary`  AS cs
    ON id.country_code = cs.country_code
  WHERE id.indicator_code = 'NY.GDP.MKTP.KD'   -- GDP (constant 2015 US$)
    AND id.value IS NOT NULL
    AND cs.region IS NOT NULL                 -- exclude aggregates w/ no region
),

median_gdp_by_region AS (
  SELECT
    region,
    -- median = 50th percentile (index 1 of 3‑tile array)
    APPROX_QUANTILES(gdp_2015_usd, 2)[OFFSET(1)] AS median_gdp
  FROM gdp_per_country_year
  GROUP BY region
)

SELECT
  region,
  median_gdp
FROM median_gdp_by_region
ORDER BY median_gdp DESC
LIMIT 1;