WITH high_income_countries AS (
  SELECT 
    country_code,
    short_name AS country_name,
    region
  FROM `bigquery-public-data.world_bank_wdi.country_summary`
  WHERE income_group = 'High income'
),

birth_rates_80s AS (
  SELECT 
    d.country_code,
    d.value
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS d
  JOIN high_income_countries AS h
    ON h.country_code = d.country_code
  WHERE d.indicator_code = 'SP.DYN.CBRT.IN'          -- crude birth rate
    AND d.year BETWEEN 1980 AND 1989
),

avg_birth_rate AS (
  SELECT
    country_code,
    AVG(value) AS avg_birth_rate
  FROM birth_rates_80s
  GROUP BY country_code
),

ranked_by_region AS (
  SELECT
    h.region,
    h.country_name,
    a.avg_birth_rate,
    ROW_NUMBER() OVER (
      PARTITION BY h.region 
      ORDER BY a.avg_birth_rate DESC
    ) AS region_rank
  FROM avg_birth_rate AS a
  JOIN high_income_countries AS h
    ON h.country_code = a.country_code
)

SELECT
  region,
  country_name,
  ROUND(avg_birth_rate, 4) AS average_birth_rate_1980s
FROM ranked_by_region
WHERE region_rank = 1
ORDER BY region;