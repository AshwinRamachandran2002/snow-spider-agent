SELECT cs.`region` AS Region,
       ROUND(APPROX_QUANTILES(id.`value`, 2)[OFFSET(1)], 4) AS Median_GDP
FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS id
JOIN `bigquery-public-data.world_bank_wdi.country_summary` AS cs
  ON id.`country_code` = cs.`country_code`
WHERE id.`indicator_code` = 'NY.GDP.MKTP.KD'
  AND id.`year` = 2019
  AND cs.`region` != ''
GROUP BY cs.`region`
ORDER BY Median_GDP DESC
LIMIT 1;