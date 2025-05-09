-- Which high-income country had the highest average crude-birth-rate
-- in each World-Bank region during the 1980s (1980-1989)?
WITH high_income AS (
  SELECT
    country_code,
    short_name AS country,
    region
  FROM `bigquery-public-data.world_bank_wdi.country_summary`
  WHERE income_group LIKE 'High income%'      -- includes OECD & non-OECD
),

avg_birth_80s AS (
  SELECT
    h.region,
    h.country,
    AVG(i.value) AS avg_birth_rate
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS i
  JOIN high_income h
    ON i.country_code = h.country_code
  WHERE i.indicator_code = 'SP.DYN.CBRT.IN'   -- crude birth rate
    AND i.year BETWEEN 1980 AND 1989
    AND i.value IS NOT NULL
  GROUP BY h.region, h.country
),

ranked AS (
  SELECT
    region,
    country,
    avg_birth_rate,
    RANK() OVER (PARTITION BY region ORDER BY avg_birth_rate DESC) AS rnk
  FROM avg_birth_80s
)

SELECT
  region,
  country,
  ROUND(avg_birth_rate, 4) AS avg_birth_rate_1980s
FROM ranked
WHERE rnk = 1           -- highest in each region
ORDER BY region;