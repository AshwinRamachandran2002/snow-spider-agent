-- Region with the highest median GDP (constant 2015 US$)
WITH region_gdp AS (
  SELECT
    c.`region`,
    d.`value`
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS d
  JOIN `bigquery-public-data.world_bank_wdi.country_summary`  AS c
  ON   d.`country_code` = c.`country_code`
  WHERE d.`indicator_code` = 'NY.GDP.MKTP.KD'   -- GDP (constant 2015 US$)
    AND d.`value` IS NOT NULL                  -- keep valid GDP values
    AND c.`region` IS NOT NULL                -- ignore “blank” region
),
median_per_region AS (
  SELECT DISTINCT
    `region`,
    PERCENTILE_CONT(`value`, 0.5) OVER (PARTITION BY `region`) AS median_gdp_2015usd
  FROM region_gdp
)
SELECT
  `region`,
  median_gdp_2015usd
FROM   median_per_region
ORDER  BY median_gdp_2015usd DESC
LIMIT  1;