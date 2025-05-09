WITH high_income_countries AS (
  SELECT country_code,
         short_name  AS country,
         region
  FROM `bigquery-public-data.world_bank_wdi.country_summary`
  WHERE income_group = 'High income'
),
avg_birth_rate_80s AS (
  SELECT country_code,
         AVG(value) AS avg_birth_rate
  FROM `bigquery-public-data.world_bank_wdi.indicators_data`
  WHERE LOWER(indicator_name) LIKE '%crude%'
    AND LOWER(indicator_name) LIKE '%birth rate%'
    AND year BETWEEN 1980 AND 1989
  GROUP BY country_code
),
ranked AS (
  SELECT h.region,
         h.country,
         ROUND(a.avg_birth_rate, 2) AS avg_birth_rate_1980s,
         RANK() OVER (PARTITION BY h.region ORDER BY a.avg_birth_rate DESC) AS rnk
  FROM avg_birth_rate_80s a
  JOIN high_income_countries h USING (country_code)
)
SELECT region,
       country,
       avg_birth_rate_1980s
FROM ranked
WHERE rnk = 1
ORDER BY avg_birth_rate_1980s DESC;