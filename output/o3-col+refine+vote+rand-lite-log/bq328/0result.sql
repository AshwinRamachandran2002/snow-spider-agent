-- Which World-Bank region has the highest median GDP (constant 2015 US$)?
WITH latest_gdp AS (
  -- For every country grab the most-recent non-NULL GDP (constant 2015 US$)
  SELECT
    d.country_code,
    ARRAY_AGG(d.value IGNORE NULLS ORDER BY d.year DESC)[OFFSET(0)] AS gdp_2015usd
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS d
  WHERE d.indicator_code = 'NY.GDP.MKTP.KD'
  GROUP BY d.country_code
),
region_medians AS (
  -- Compute the median GDP within each World-Bank region
  SELECT
    cs.region,
    APPROX_QUANTILES(l.gdp_2015usd, 100)[OFFSET(50)] AS median_gdp_2015usd
  FROM latest_gdp AS l
  JOIN `bigquery-public-data.world_bank_wdi.country_summary` AS cs
    ON l.country_code = cs.country_code
  WHERE cs.region IS NOT NULL          -- keep only actual countries
  GROUP BY cs.region
)
SELECT
  region,
  median_gdp_2015usd
FROM region_medians
ORDER BY median_gdp_2015usd DESC
LIMIT 1;