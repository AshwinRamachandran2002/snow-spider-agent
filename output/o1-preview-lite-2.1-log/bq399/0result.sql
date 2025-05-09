SELECT x.`region`, x.`short_name` AS country, ROUND(x.`avg_crude_birth_rate`, 4) AS average_crude_birth_rate
FROM (
  SELECT cs.`region`, cs.`short_name`, AVG(id.`value`) AS avg_crude_birth_rate,
    ROW_NUMBER() OVER (PARTITION BY cs.`region` ORDER BY AVG(id.`value`) DESC) AS rn
  FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS id
  JOIN `bigquery-public-data.world_bank_wdi.country_summary` AS cs
    ON id.`country_code` = cs.`country_code`
  WHERE id.`indicator_code` = 'SP.DYN.CBRT.IN'
    AND id.`year` BETWEEN 1980 AND 1989
    AND cs.`income_group` LIKE 'High income%'
  GROUP BY cs.`region`, cs.`short_name`
) AS x
WHERE x.rn = 1;