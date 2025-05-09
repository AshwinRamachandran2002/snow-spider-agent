WITH country_80s_avg AS (
  SELECT
    cs.region,
    d.country_name,
    AVG(d.value) AS avg_birth_rate
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS d
  JOIN `bigquery-public-data.world_bank_wdi.country_summary` AS cs
    ON d.country_code = cs.country_code
  WHERE d.indicator_code = 'SP.DYN.CBRT.IN'       -- crude birth rate
    AND d.year BETWEEN 1980 AND 1989              -- the 1980s
    AND cs.income_group = 'High income'           -- high‑income economies
    AND d.value IS NOT NULL
  GROUP BY cs.region, d.country_name
),
ranked AS (
  SELECT
    region,
    country_name,
    avg_birth_rate,
    RANK() OVER (PARTITION BY region ORDER BY avg_birth_rate DESC) AS rnk
  FROM country_80s_avg
)
SELECT
  region,
  country_name AS highest_birth_rate_country,
  FORMAT('%.4f', ROUND(avg_birth_rate, 4)) AS average_crude_birth_rate_1980s
FROM ranked
WHERE rnk = 1
ORDER BY region;