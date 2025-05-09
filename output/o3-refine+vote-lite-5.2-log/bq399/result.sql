-- High‑income country with the highest average crude birth rate (per 1,000 people)
-- in every World Bank region during the 1980s (1980‑1989)

WITH high_income_countries AS (
  SELECT
    country_code,
    region,
    short_name
  FROM `bigquery-public-data.world_bank_wdi.country_summary`
  WHERE income_group = 'High income'
    AND region IS NOT NULL               -- exclude aggregates that lack a region
    AND region <> 'Aggregates'           -- extra safety: drop explicit Aggregate tag
),

avg_birth_rate_80s AS (
  SELECT
    country_code,
    AVG(value) AS avg_birth_rate_80s
  FROM `bigquery-public-data.world_bank_wdi.indicators_data`
  WHERE indicator_code = 'SP.DYN.CBRT.IN'   -- Crude birth rate (per 1,000 people)
    AND year BETWEEN 1980 AND 1989          -- the 1980s decade
    AND value IS NOT NULL
  GROUP BY country_code
),

ranked AS (
  SELECT
    h.region,
    h.short_name        AS country,
    a.avg_birth_rate_80s,
    ROW_NUMBER() OVER (PARTITION BY h.region
                       ORDER BY a.avg_birth_rate_80s DESC) AS rn
  FROM high_income_countries h
  JOIN avg_birth_rate_80s    a
    ON h.country_code = a.country_code
)

SELECT
  region,
  country,
  avg_birth_rate_80s AS average_crude_birth_rate_1980s
FROM ranked
WHERE rn = 1                -- keep the top country per region
ORDER BY region;