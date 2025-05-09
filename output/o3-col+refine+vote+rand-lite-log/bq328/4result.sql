WITH region_medians AS (
  SELECT
    cs.region,
    -- median (50th percentile) GDP in constant 2015 US$
    APPROX_QUANTILES(id.value, 2)[OFFSET(1)] AS median_gdp_const_2015
  FROM
    `bigquery-public-data.world_bank_wdi.indicators_data` AS id
  JOIN
    `bigquery-public-data.world_bank_wdi.country_summary` AS cs
  ON
    id.country_code = cs.country_code
  WHERE
    id.indicator_code = 'NY.GDP.MKTP.KD'   -- GDP (constant 2015 US$)
    AND cs.region IS NOT NULL              -- keep only actual regions
  GROUP BY
    cs.region
)
SELECT
  region,
  median_gdp_const_2015
FROM
  region_medians
ORDER BY
  median_gdp_const_2015 DESC
LIMIT 1;