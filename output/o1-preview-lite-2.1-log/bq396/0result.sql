SELECT
  `state_name` AS State,
  ABS(
    SUM(CASE WHEN `atmospheric_conditions_1_name` = 'Rain' THEN 1 ELSE 0 END) -
    SUM(CASE WHEN `atmospheric_conditions_1_name` = 'Clear' THEN 1 ELSE 0 END)
  ) AS Difference
FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
WHERE
  `year_of_crash` = 2016
  AND `day_of_week` IN (1, 7)
  AND `atmospheric_conditions_1_name` IN ('Rain', 'Clear')
GROUP BY `state_name`
ORDER BY Difference DESC
LIMIT 3;