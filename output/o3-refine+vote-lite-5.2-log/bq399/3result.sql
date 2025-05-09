WITH birth_rate_80s AS (
  -- 1.  Average crude birth rate for every country during 1980‑1989
  SELECT
    country_code,
    AVG(value) AS avg_birth_rate_80s
  FROM `bigquery-public-data.world_bank_wdi.indicators_data`
  WHERE indicator_code = 'SP.DYN.CBRT.IN'          -- crude birth rate (per 1,000 people)
    AND year BETWEEN 1980 AND 1989
    AND value IS NOT NULL
  GROUP BY country_code
),
high_income_countries AS (
  -- 2.  Keep only high‑income economies and bring their region names
  SELECT
    country_code,
    short_name                AS country_name,
    region
  FROM `bigquery-public-data.world_bank_wdi.country_summary`
  WHERE income_group LIKE 'High income%'           -- covers “High income”, “High income: OECD”, etc.
),
combined AS (
  -- 3.  Join the two sets
  SELECT
    h.region,
    h.country_name,
    b.avg_birth_rate_80s
  FROM birth_rate_80s b
  JOIN high_income_countries h
    ON b.country_code = h.country_code
),
ranked AS (
  -- 4.  Rank countries inside every region by their average birth rate
  SELECT
    region,
    country_name,
    avg_birth_rate_80s,
    ROW_NUMBER() OVER (PARTITION BY region
                       ORDER BY avg_birth_rate_80s DESC, country_name) AS rn
  FROM combined
)
-- 5.  Pick the top‑ranked (highest birth rate) country for each region
SELECT
  region,
  country_name  AS highest_avg_birth_rate_country,
  avg_birth_rate_80s
FROM ranked
WHERE rn = 1
ORDER BY region;