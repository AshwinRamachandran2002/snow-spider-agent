WITH gdp AS (
  SELECT
    c.region,
    i.value
  FROM
    `bigquery-public-data.world_bank_wdi.indicators_data` AS i
  JOIN
    `bigquery-public-data.world_bank_wdi.country_summary` AS c
  ON
    i.country_code = c.country_code
  WHERE
    i.indicator_code = 'NY.GDP.MKTP.KD'        -- GDP (constant 2015 US$)
    AND c.region IS NOT NULL                   -- keep only actual regions
    AND i.value IS NOT NULL                    -- exclude missing GDP values
),
region_median AS (
  SELECT
    region,
    APPROX_QUANTILES(value, 2)[OFFSET(1)] AS median_gdp   -- median per region
  FROM
    gdp
  GROUP BY
    region
),
ranked AS (
  SELECT
    region,
    median_gdp,
    RANK() OVER (ORDER BY median_gdp DESC) AS rnk
  FROM
    region_median
)
SELECT
  region,
  median_gdp
FROM
  ranked
WHERE
  rnk = 1;