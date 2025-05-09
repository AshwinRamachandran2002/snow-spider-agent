SELECT
    cs.region AS Region,
    ROUND(APPROX_QUANTILES(i.value, 2)[OFFSET(1)], 4) AS Median_GDP
FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS i
JOIN `bigquery-public-data.world_bank_wdi.country_summary` AS cs
ON i.country_code = cs.country_code
WHERE i.indicator_code = 'NY.GDP.MKTP.KD'
  AND i.year = 2019
  AND cs.region IS NOT NULL
GROUP BY cs.region
ORDER BY Median_GDP DESC
LIMIT 1;