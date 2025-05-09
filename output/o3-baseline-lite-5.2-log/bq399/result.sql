WITH birth_rate AS (
  -- Crude birth‑rate observations for the 1980‑1989 period
  SELECT
    country_code,
    value,
    year
  FROM `bigquery-public-data.world_bank_wdi.indicators_data`
  WHERE indicator_code = 'SP.DYN.CBRT.IN'
    AND year BETWEEN 1980 AND 1989
),
country_info AS (
  -- Keep only high‑income countries and their regions
  SELECT
    country_code,
    short_name          AS country,
    region,
    income_group
  FROM `bigquery-public-data.world_bank_wdi.country_summary`
  WHERE LOWER(income_group) LIKE '%high income%'          -- “High income”, “High income: OECD”, etc.
),
avg_birth AS (
  -- Average crude birth rate in the 1980s for each high‑income country
  SELECT
    ci.region,
    ci.country,
    AVG(br.value) AS avg_birth_rate
  FROM birth_rate br
  JOIN country_info ci USING (country_code)
  WHERE br.value IS NOT NULL
    AND ci.region IS NOT NULL
    AND LOWER(ci.region) NOT LIKE '%aggregate%'           -- drop aggregate pseudo‑countries
  GROUP BY ci.region, ci.country
),
ranked AS (
  -- Rank countries by average birth rate within each region
  SELECT
    region,
    country,
    avg_birth_rate,
    ROW_NUMBER() OVER (PARTITION BY region
                       ORDER BY avg_birth_rate DESC) AS rn
  FROM avg_birth
)
-- Highest‑average crude birth‑rate country in each region
SELECT
  region,
  country                         AS highest_birth_rate_country,
  ROUND(avg_birth_rate, 4)        AS average_birth_rate_1980s
FROM ranked
WHERE rn = 1
ORDER BY region;