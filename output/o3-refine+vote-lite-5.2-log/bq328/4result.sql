-- Region with the highest median GDP (constant 2015 US$)
WITH gdp AS (
  SELECT
    cs.region,
    d.value
  FROM
    `bigquery-public-data.world_bank_wdi.indicators_data` AS d
  JOIN
    `bigquery-public-data.world_bank_wdi.country_summary` AS cs
  ON
    d.country_code = cs.country_code
  WHERE
    d.indicator_code = 'NY.GDP.MKTP.KD'      -- GDP (constant 2015 US$)
    AND d.value IS NOT NULL
    AND cs.region IS NOT NULL
),
region_median AS (
  SELECT
    region,
    APPROX_QUANTILES(value, 2)[OFFSET(1)] AS median_gdp   -- 50th percentile
  FROM
    gdp
  GROUP BY
    region
)
SELECT
  region,
  median_gdp
FROM
  region_median
ORDER BY
  median_gdp DESC
LIMIT 1;