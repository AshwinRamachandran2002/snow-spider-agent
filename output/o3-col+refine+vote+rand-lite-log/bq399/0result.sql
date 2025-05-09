-- Which high-income country recorded the highest average crude birth rate in each region during the 1980s?
WITH avg_1980s AS (
  SELECT
    cs.region,
    cs.short_name AS country,
    AVG(id.value) AS avg_birth_rate_1980s
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS id
  JOIN `bigquery-public-data.world_bank_wdi.country_summary` AS cs
    ON id.country_code = cs.country_code
  WHERE id.indicator_code = 'SP.DYN.CBRT.IN'      -- Crude birth rate (per 1,000 people)
    AND id.year BETWEEN 1980 AND 1989
    AND cs.income_group = 'High income'
  GROUP BY cs.region, cs.short_name
),
ranked AS (
  SELECT
    region,
    country,
    avg_birth_rate_1980s,
    ROW_NUMBER() OVER (PARTITION BY region ORDER BY avg_birth_rate_1980s DESC) AS rn
  FROM avg_1980s
)
SELECT
  region,
  country AS high_income_country_with_highest_birth_rate,
  ROUND(avg_birth_rate_1980s, 2) AS avg_birth_rate_per_1000_people_1980s
FROM ranked
WHERE rn = 1
ORDER BY region;