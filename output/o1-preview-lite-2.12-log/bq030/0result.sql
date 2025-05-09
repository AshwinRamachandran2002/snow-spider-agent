SELECT `country_name` AS `Country`,
       ROUND((`cumulative_recovered` / `cumulative_confirmed`) * 100, 4) AS `Recovery_Rate_Percentage`
FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE
    `date` = '2020-05-10' AND
    `aggregation_level` = 0 AND
    `cumulative_confirmed` > 50000 AND
    `cumulative_confirmed` IS NOT NULL AND
    `cumulative_recovered` IS NOT NULL AND
    `cumulative_recovered` <= `cumulative_confirmed`
ORDER BY `Recovery_Rate_Percentage` DESC
LIMIT 3