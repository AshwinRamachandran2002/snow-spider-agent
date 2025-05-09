WITH regional_medians AS (
  SELECT
    cs.region,
    APPROX_QUANTILES(id.value, 100)[OFFSET(50)] AS median_gdp_constant_2015_usd
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` id
  JOIN `bigquery-public-data.world_bank_wdi.country_summary` cs
    USING (country_code)
  WHERE id.indicator_code = 'NY.GDP.MKTP.KD'      -- GDP (constant 2015 US$)
    AND id.value IS NOT NULL
    AND cs.region IS NOT NULL                     -- exclude aggregates with no region
  GROUP BY cs.region
)
SELECT
  region,
  ROUND(median_gdp_constant_2015_usd, 4) AS median_gdp_constant_2015_usd
FROM regional_medians
ORDER BY median_gdp_constant_2015_usd DESC
LIMIT 1;