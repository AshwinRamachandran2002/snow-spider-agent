WITH gdp_values AS (
  SELECT
    cs.region,
    id.value
  FROM
    `bigquery-public-data.world_bank_wdi.indicators_data` AS id
  JOIN
    `bigquery-public-data.world_bank_wdi.country_summary` AS cs
  ON
    id.country_code = cs.country_code
  WHERE
    id.indicator_code = 'NY.GDP.MKTP.KD'        -- GDP (constant 2015 US$)
    AND id.value IS NOT NULL
    AND cs.region IS NOT NULL                  -- keep only actual regions
),
region_medians AS (
  SELECT
    region,
    APPROX_QUANTILES(value, 2)[OFFSET(1)] AS median_gdp_2015usd   -- median
  FROM
    gdp_values
  GROUP BY
    region
)
SELECT
  region,
  median_gdp_2015usd
FROM
  region_medians
ORDER BY
  median_gdp_2015usd DESC
LIMIT 1;