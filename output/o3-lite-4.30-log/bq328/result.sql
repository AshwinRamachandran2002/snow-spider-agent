WITH region_values AS (
  SELECT
    cs.region,
    d.value
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS d
  JOIN `bigquery-public-data.world_bank_wdi.country_summary` AS cs
    ON d.country_code = cs.country_code
  WHERE d.indicator_code = 'NY.GDP.MKTP.KD'      -- GDP (constant 2015 US$)
    AND cs.region IS NOT NULL                    -- keep only standard WB regions
),
region_median AS (
  SELECT
    region,
    ROUND(PERCENTILE_CONT(value, 0.5) OVER (PARTITION BY region), 4) AS median_gdp_constant_2015_usd
  FROM region_values
)
SELECT region, median_gdp_constant_2015_usd
FROM region_median
QUALIFY ROW_NUMBER() OVER (ORDER BY median_gdp_constant_2015_usd DESC, region) = 1;