WITH birth_rate_80s AS (
  -- 1.  Average crude birth rate for every high‑income country during 1980‑1989
  SELECT
    cs.region,
    id.country_code,
    id.country_name,
    AVG(id.value) AS avg_birth_rate
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS id
  JOIN `bigquery-public-data.world_bank_wdi.country_summary` AS cs
    ON id.country_code = cs.country_code
  WHERE id.indicator_code = 'SP.DYN.CBRT.IN'          -- crude birth rate
    AND id.year BETWEEN 1980 AND 1989                 -- the 1980s
    AND cs.income_group = 'High income'               -- only high‑income economies
    AND cs.region IS NOT NULL                         -- keep countries assigned to a region
  GROUP BY cs.region, id.country_code, id.country_name
),
ranked AS (
  -- 2.  Rank countries within each region by average birth rate
  SELECT
    region,
    country_name,
    avg_birth_rate,
    RANK() OVER (PARTITION BY region ORDER BY avg_birth_rate DESC) AS rnk
  FROM birth_rate_80s
)
-- 3.  Pick the top‑ranked (highest average) country in every region
SELECT
  region,
  country_name  AS country,
  ROUND(avg_birth_rate, 4) AS average_birth_rate_1980s
FROM ranked
WHERE rnk = 1
ORDER BY region;