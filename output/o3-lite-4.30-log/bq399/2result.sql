WITH country_avg AS (
  SELECT
    d.country_code,
    ANY_VALUE(d.country_name) AS country_name,
    ANY_VALUE(c.region)       AS region,
    AVG(d.value)              AS avg_crude_birth_rate_1980s
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS d
  JOIN `bigquery-public-data.world_bank_wdi.country_summary`  AS c
    ON d.country_code = c.country_code
  WHERE d.indicator_code = 'SP.DYN.CBRT.IN'
    AND d.year BETWEEN 1980 AND 1989
    AND c.income_group LIKE 'High income%'
    AND c.region IS NOT NULL
  GROUP BY d.country_code
),
ranked AS (
  SELECT
    region,
    country_name,
    avg_crude_birth_rate_1980s,
    RANK() OVER (PARTITION BY region ORDER BY avg_crude_birth_rate_1980s DESC) AS rnk
  FROM country_avg
)
SELECT
  region,
  country_name AS highest_birth_rate_country,
  ROUND(avg_crude_birth_rate_1980s, 4) AS average_crude_birth_rate_1980s
FROM ranked
WHERE rnk = 1
ORDER BY region;