-- Region with the highest median GDP (constant 2015 US$)
WITH latest_gdp AS (
  -- keep the most recent non‑NULL GDP observation for every country
  SELECT
    country_code,
    value AS gdp_2015_usd
  FROM (
    SELECT
      country_code,
      value,
      ROW_NUMBER() OVER (PARTITION BY country_code ORDER BY year DESC) AS rn
    FROM `bigquery-public-data.world_bank_wdi.indicators_data`
    WHERE indicator_code = 'NY.GDP.MKTP.KD'     -- GDP, constant 2015 US$
      AND value IS NOT NULL
  )
  WHERE rn = 1
),
gdp_with_region AS (
  -- attach World Bank region information
  SELECT
    cs.region,
    lg.gdp_2015_usd
  FROM latest_gdp AS lg
  JOIN `bigquery-public-data.world_bank_wdi.country_summary` AS cs
  USING (country_code)
  WHERE cs.region IS NOT NULL                  -- exclude aggregates with no region
),
region_medians AS (
  -- median GDP for each region
  SELECT
    region,
    APPROX_QUANTILES(gdp_2015_usd, 2)[OFFSET(1)] AS median_gdp
  FROM gdp_with_region
  GROUP BY region
)
SELECT region, median_gdp
FROM region_medians
ORDER BY median_gdp DESC
LIMIT 1;