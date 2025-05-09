-- Which region has the highest median GDP (constant 2015 US$)?
SELECT
  cs.region,
  APPROX_QUANTILES(id.value, 2)[OFFSET(1)] AS median_gdp_2015_usd
FROM
  `bigquery-public-data.world_bank_wdi.indicators_data` AS id
JOIN
  `bigquery-public-data.world_bank_wdi.country_summary` AS cs
ON
  id.country_code = cs.country_code
WHERE
  id.indicator_code = 'NY.GDP.MKTP.KD'     -- GDP (constant 2015 US$)
  AND cs.region IS NOT NULL                -- exclude aggregates with no region
  AND id.value IS NOT NULL                 -- ensure valid GDP values
GROUP BY
  cs.region
ORDER BY
  median_gdp_2015_usd DESC
LIMIT 1;