SELECT
  region,
  country                         AS highest_birth_rate_country,
  ROUND(avg_birth_rate_1980s, 4)  AS average_crude_birth_rate_1980s
FROM (
  SELECT
    cs.region,
    cs.short_name                 AS country,
    AVG(id.value)                 AS avg_birth_rate_1980s,
    ROW_NUMBER() OVER (
      PARTITION BY cs.region
      ORDER BY AVG(id.value) DESC
    )                             AS rn
  FROM `bigquery-public-data.world_bank_wdi.indicators_data`   AS id
  JOIN `bigquery-public-data.world_bank_wdi.country_summary`   AS cs
    USING (country_code)
  WHERE id.indicator_code = 'SP.DYN.CBRT.IN'
    AND id.year BETWEEN 1980 AND 1989
    AND cs.income_group = 'High income'
  GROUP BY cs.region, cs.short_name
)
WHERE rn = 1
ORDER BY region;