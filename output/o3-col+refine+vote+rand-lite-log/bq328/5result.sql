-- Which region has the highest median GDP (constant 2015 US$)?
WITH regional_medians AS (
  SELECT
    cs.region,
    -- approximate median of all GDP values (constant 2015 US$) for the region
    APPROX_QUANTILES(d.value, 2)[OFFSET(1)] AS median_gdp_2015_usd
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS d
  JOIN `bigquery-public-data.world_bank_wdi.country_summary` AS cs
    ON d.country_code = cs.country_code
  WHERE d.indicator_code = 'NY.GDP.MKTP.KD'   -- GDP (constant 2015 US$)
    AND cs.region IS NOT NULL                -- keep valid regions
    AND d.value IS NOT NULL                  -- exclude missing GDP values
  GROUP BY cs.region
)
SELECT
  region AS highest_median_gdp_region,
  median_gdp_2015_usd
FROM regional_medians
ORDER BY median_gdp_2015_usd DESC
LIMIT 1;