-- Task: For each state, find the number of traffic accidents during weekends in 2016 under rainy and clear weather conditions.

SELECT `state_name`,
    SUM(CASE WHEN `atmospheric_conditions_1_name` = 'Rain' THEN 1 ELSE 0 END) AS `Rain_Count`,
    SUM(CASE WHEN `atmospheric_conditions_1_name` = 'Clear' THEN 1 ELSE 0 END) AS `Clear_Count`
FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
WHERE `year_of_crash` = 2016
  AND `day_of_week` IN (1, 7)  -- 1: Sunday, 7: Saturday
  AND `atmospheric_conditions_1_name` IN ('Rain', 'Clear')
GROUP BY `state_name`;