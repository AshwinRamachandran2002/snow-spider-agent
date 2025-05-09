SELECT sub.region AS Region, sub.country_name AS Country, ROUND(sub.avg_crude_birth_rate, 4) AS Average_Crude_Birth_Rate
FROM (
  SELECT cs.region, ind.country_name,
         AVG(ind.value) AS avg_crude_birth_rate,
         ROW_NUMBER() OVER (PARTITION BY cs.region ORDER BY AVG(ind.value) DESC) AS rn
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS ind
  JOIN `bigquery-public-data.world_bank_wdi.country_summary` AS cs
    ON ind.country_code = cs.country_code
  WHERE ind.indicator_code = 'SP.DYN.CBRT.IN'
    AND ind.year BETWEEN 1980 AND 1989
    AND cs.income_group = 'High income'
    AND cs.region IS NOT NULL
  GROUP BY cs.region, ind.country_name
) sub
WHERE sub.rn = 1
ORDER BY sub.region;