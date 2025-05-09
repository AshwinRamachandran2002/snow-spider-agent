-- Which high-income country recorded the highest average crude-birth-rate
-- in each World-Bank region during the 1980s (1980-1989 inclusive)?

WITH avg_80s AS (
  SELECT
    cs.region,
    cs.country_code,
    cs.short_name                 AS country,
    AVG(id.value)                 AS avg_birth_rate_80s
  FROM `bigquery-public-data.world_bank_wdi.indicators_data`   AS id
  JOIN `bigquery-public-data.world_bank_wdi.country_summary`   AS cs
    ON id.country_code = cs.country_code
  WHERE id.indicator_code = 'SP.DYN.CBRT.IN'        -- crude birth rate
    AND id.year BETWEEN 1980 AND 1989               -- 1980s window
    AND cs.income_group LIKE 'High income%'         -- high-income economies
    AND id.value IS NOT NULL
  GROUP BY cs.region, cs.country_code, cs.short_name
),
ranked AS (
  SELECT
    region,
    country_code,
    country,
    avg_birth_rate_80s,
    ROW_NUMBER() OVER (PARTITION BY region
                       ORDER BY avg_birth_rate_80s DESC) AS rn
  FROM avg_80s
)

SELECT
  region,
  country_code,
  country,
  ROUND(avg_birth_rate_80s, 2) AS avg_birth_rate_80s
FROM ranked
WHERE rn = 1
ORDER BY region;