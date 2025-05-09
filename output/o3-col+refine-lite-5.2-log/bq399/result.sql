-- High‑income country with the highest average crude birth rate (1980‑1989) in each World Bank region
SELECT
  region,
  country_name AS high_income_country,
  ROUND(avg_birth_rate_80s, 2) AS average_birth_rate_1980s
FROM (
  SELECT
    cs.region,
    id.country_name,
    AVG(id.value) AS avg_birth_rate_80s,
    RANK() OVER (PARTITION BY cs.region ORDER BY AVG(id.value) DESC) AS rnk
  FROM
    `bigquery-public-data.world_bank_wdi.indicators_data` AS id
  JOIN
    `bigquery-public-data.world_bank_wdi.country_summary` AS cs
  ON
    id.country_code = cs.country_code
  WHERE
    id.indicator_code = 'SP.DYN.CBRT.IN'         -- Crude birth rate (per 1,000 people)
    AND id.year BETWEEN 1980 AND 1989            -- 1980s
    AND cs.income_group LIKE '%High income%'     -- High‑income economies
    AND id.value IS NOT NULL                     -- Ensure valid observations
  GROUP BY
    cs.region,
    id.country_name
)
WHERE
  rnk = 1                                         -- Top country per region
ORDER BY
  region;