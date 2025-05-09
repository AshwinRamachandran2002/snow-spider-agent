-- Highest-average crude birth-rate high-income country in every World-Bank region (1980-1989)
SELECT
  region,
  country_name,
  ROUND(avg_birthrate_1980s, 2) AS avg_birthrate_1980s
FROM (
  SELECT
    cs.region,
    cs.short_name AS country_name,
    AVG(id.value) AS avg_birthrate_1980s,
    RANK() OVER (PARTITION BY cs.region ORDER BY AVG(id.value) DESC) AS rnk
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS id
  JOIN `bigquery-public-data.world_bank_wdi.country_summary`   AS cs
    ON id.country_code = cs.country_code
  WHERE id.indicator_code = 'SP.DYN.CBRT.IN'        -- crude birth rate
    AND id.year BETWEEN 1980 AND 1989               -- the 1980s
    AND cs.income_group = 'High income'             -- high-income economies
    AND cs.region IS NOT NULL                       -- keep only standard regions
  GROUP BY cs.region, cs.short_name
) AS ranked
WHERE rnk = 1                                         -- top country per region
ORDER BY region;