WITH avg_birth AS (
  SELECT
    c.region,
    c.short_name,
    AVG(d.value) AS avg_birth_rate_1980s
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS d
  JOIN `bigquery-public-data.world_bank_wdi.country_summary` AS c
    USING (country_code)
  WHERE c.income_group = 'High income'
    AND d.indicator_code = 'SP.DYN.CBRT.IN'   -- crude birth rate
    AND d.year BETWEEN 1980 AND 1989          -- the 1980s decade
  GROUP BY c.region, c.short_name
),
ranked AS (
  SELECT
    region,
    short_name,
    avg_birth_rate_1980s,
    ROW_NUMBER() OVER (PARTITION BY region ORDER BY avg_birth_rate_1980s DESC) AS rn
  FROM avg_birth
)
SELECT
  region   AS world_bank_region,
  short_name AS high_income_country_with_highest_avg_1980s_birth_rate,
  ROUND(avg_birth_rate_1980s, 2) AS average_crude_birth_rate_1980s
FROM ranked
WHERE rn = 1
ORDER BY world_bank_region;