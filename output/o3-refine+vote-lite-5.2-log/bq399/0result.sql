WITH high_income_countries AS (
  SELECT
    country_code,
    region
  FROM
    `bigquery-public-data.world_bank_wdi.country_summary`
  WHERE
    region IS NOT NULL
    AND income_group LIKE 'High income%'          -- keep only high‑income economies
),
birth_80s AS (
  SELECT
    country_code,
    country_name,
    value AS birth_rate
  FROM
    `bigquery-public-data.world_bank_wdi.indicators_data`
  WHERE
    indicator_code = 'SP.DYN.CBRT.IN'             -- crude birth rate (per 1,000 people)
    AND year BETWEEN 1980 AND 1989
    AND value IS NOT NULL
),
avg_birth_rate AS (
  SELECT
    h.region,
    b.country_code,
    MAX(b.country_name) AS country_name,
    AVG(b.birth_rate)   AS avg_birth_rate
  FROM
    birth_80s b
    JOIN high_income_countries h USING (country_code)
  GROUP BY
    h.region,
    b.country_code
),
ranked AS (
  SELECT
    region,
    country_name,
    ROUND(abr.avg_birth_rate, 4) AS avg_birth_rate,
    ROW_NUMBER() OVER (PARTITION BY region ORDER BY abr.avg_birth_rate DESC) AS rn
  FROM
    avg_birth_rate abr
)
SELECT
  region,
  country_name,
  avg_birth_rate
FROM
  ranked
WHERE
  rn = 1
ORDER BY
  region;