SELECT
  region,
  country_name,
  ROUND(average_birth_rate, 4) AS average_birth_rate
FROM (
  SELECT
    c.region,
    i.country_name,
    AVG(i.value) AS average_birth_rate,
    ROW_NUMBER() OVER (PARTITION BY c.region ORDER BY AVG(i.value) DESC) AS rn
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS i
  JOIN `bigquery-public-data.world_bank_wdi.country_summary` AS c
    ON i.country_code = c.country_code
  WHERE i.indicator_code = 'SP.DYN.CBRT.IN'
    AND i.year BETWEEN 1980 AND 1989
    AND c.income_group = 'High income'
  GROUP BY c.region, i.country_name
)
WHERE rn = 1;