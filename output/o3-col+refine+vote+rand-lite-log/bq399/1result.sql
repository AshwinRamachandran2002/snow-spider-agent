-- Which high-income country recorded the highest average crude-birth-rate
-- in each World Bank region during the 1980s (1980-1989)?
WITH cbr AS (
  SELECT
    country_code,
    AVG(value) AS avg_cbr_1980s
  FROM `bigquery-public-data.world_bank_wdi.indicators_data`
  WHERE indicator_code = 'SP.DYN.CBRT.IN'
    AND year BETWEEN 1980 AND 1989
  GROUP BY country_code
),
ranked AS (
  SELECT
    cs.region,
    cs.short_name AS country,
    cbr.avg_cbr_1980s,
    DENSE_RANK() OVER (
      PARTITION BY cs.region
      ORDER BY cbr.avg_cbr_1980s DESC
    ) AS rnk
  FROM cbr
  JOIN `bigquery-public-data.world_bank_wdi.country_summary` AS cs
    ON cs.country_code = cbr.country_code
  WHERE cs.income_group = 'High income'
)
SELECT
  region,
  country,
  avg_cbr_1980s
FROM ranked
WHERE rnk = 1
ORDER BY region;