WITH birth_80s AS (
  -- 1.  Compute each high-income country’s average crude birth rate for 1980-1989
  SELECT
    cs.region,
    cs.short_name AS country,
    AVG(id.value) AS avg_birth_rate
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS id
  JOIN `bigquery-public-data.world_bank_wdi.country_summary`   AS cs
    ON cs.country_code = id.country_code
  WHERE id.indicator_code = 'SP.DYN.CBRT.IN'     -- crude birth rate
    AND id.year BETWEEN 1980 AND 1989            -- 1980-1989 window
    AND cs.income_group LIKE 'High income%'      -- high-income economies only
    AND id.value IS NOT NULL                     -- keep valid data points
  GROUP BY cs.region, cs.short_name
),
ranked AS (
  -- 2.  Rank countries within each region by their average birth rate
  SELECT
    region,
    country,
    avg_birth_rate,
    ROW_NUMBER() OVER (PARTITION BY region
                       ORDER BY avg_birth_rate DESC) AS rn
  FROM birth_80s
)
-- 3.  Return the top-ranked (highest average) high-income country per region
SELECT
  region,
  country,
  ROUND(avg_birth_rate, 2) AS avg_birth_rate_1980s
FROM ranked
WHERE rn = 1
ORDER BY region;