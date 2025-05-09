WITH region_medians AS (
  SELECT
    c.region,
    ROUND(APPROX_QUANTILES(i.value, 2)[OFFSET(1)], 4) AS median_gdp_constant_2015_usd
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS i
  JOIN `bigquery-public-data.world_bank_wdi.country_summary` AS c
    USING (country_code)
  WHERE i.indicator_code = 'NY.GDP.MKTP.KD'   -- GDP (constant 2015 US$)
    AND i.value IS NOT NULL
    AND c.region IS NOT NULL                  -- exclude aggregates with no region
  GROUP BY c.region
)

SELECT region, median_gdp_constant_2015_usd
FROM region_medians
ORDER BY median_gdp_constant_2015_usd DESC
LIMIT 1;