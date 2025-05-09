WITH birth_rate_80s AS (
  -- 1. Birth‑rate time‑series filtered to the 1980‑1989 decade
  SELECT
    d.country_code,
    c.short_name         AS country_name,
    c.region,
    AVG(d.value)         AS avg_birth_rate   -- decade average
  FROM `bigquery-public-data.world_bank_wdi.indicators_data`  AS d
  JOIN `bigquery-public-data.world_bank_wdi.country_summary`  AS c
    ON d.country_code = c.country_code
  WHERE d.indicator_code = 'SP.DYN.CBRT.IN'        -- crude birth rate (per 1,000 people)
    AND d.year BETWEEN 1980 AND 1989               -- the 1980s
    AND c.income_group LIKE 'High income%'         -- high‑income economies (both OECD & non‑OECD)
    AND c.region IS NOT NULL                       -- exclude aggregates without a region
  GROUP BY d.country_code, c.short_name, c.region
),

regional_leaders AS (
  -- 2. Pick the highest‑average country in each region
  SELECT
    region,
    country_name,
    avg_birth_rate,
    ROW_NUMBER() OVER (PARTITION BY region ORDER BY avg_birth_rate DESC) AS rn
  FROM birth_rate_80s
)

-- 3. Final answer: one country per region
SELECT
  region,
  country_name,
  ROUND(avg_birth_rate, 4) AS avg_birth_rate_1980s
FROM regional_leaders
WHERE rn = 1
ORDER BY region;