WITH birth_80s AS (
  /* Average crude birth rate (per 1,000 people) for 1980‑1989 */
  SELECT
    id.country_code,
    ANY_VALUE(id.country_name)       AS country_name,
    AVG(id.value)                    AS avg_birth_rate
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS id
  WHERE id.indicator_code = 'SP.DYN.CBRT.IN'
    AND id.year BETWEEN 1980 AND 1989
    AND id.value IS NOT NULL
  GROUP BY id.country_code
),

high_income AS (
  /* Keep only high‑income countries and attach their region */
  SELECT
    b.country_code,
    b.country_name,
    b.avg_birth_rate,
    cs.region
  FROM birth_80s b
  JOIN `bigquery-public-data.world_bank_wdi.country_summary` cs
    ON b.country_code = cs.country_code
  WHERE cs.income_group = 'High income'
    AND cs.region IS NOT NULL
),

ranked AS (
  /* Rank countries by average birth rate within each region */
  SELECT
    region,
    country_name,
    avg_birth_rate,
    ROW_NUMBER() OVER (PARTITION BY region
                       ORDER BY avg_birth_rate DESC, country_name) AS rn
  FROM high_income
)

SELECT
  region,
  country_name,
  ROUND(avg_birth_rate, 4) AS average_birth_rate
FROM ranked
WHERE rn = 1
ORDER BY region;