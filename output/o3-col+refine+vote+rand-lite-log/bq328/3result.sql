SELECT region
FROM (
  SELECT
    cs.region,
    APPROX_QUANTILES(id.value, 2)[OFFSET(1)] AS median_gdp_2019
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS id
  JOIN `bigquery-public-data.world_bank_wdi.country_summary` AS cs
    ON id.country_code = cs.country_code
  WHERE id.indicator_code = 'NY.GDP.MKTP.KD'   -- GDP (constant 2015 US$)
    AND id.year = 2019                         -- chosen common latest year
    AND cs.region IS NOT NULL                 -- exclude aggregate/non-regional rows
  GROUP BY cs.region
  ORDER BY median_gdp_2019 DESC
  LIMIT 1
);