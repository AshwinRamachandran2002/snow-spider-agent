-- Task: Identify the top 3 U.S. states in 2016 with the largest absolute difference in the number of traffic accidents between 'Rain' and 'Clear' atmospheric conditions during weekends (Saturdays and Sundays). Only consider accidents that occurred in 'Rain' or 'Clear' conditions on weekends in 2016. Provide the state names along with the respective absolute differences.

SELECT `state_name`,
       ABS(
         SUM(CASE WHEN `atmospheric_conditions_1_name` = 'Rain' THEN 1 ELSE 0 END) -
         SUM(CASE WHEN `atmospheric_conditions_1_name` = 'Clear' THEN 1 ELSE 0 END)
       ) AS `Difference`
FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
WHERE `year_of_crash` = 2016
  AND `day_of_week` IN (1, 7)  -- 1: Sunday, 7: Saturday
  AND `atmospheric_conditions_1_name` IN ('Rain', 'Clear')
GROUP BY `state_name`
ORDER BY `Difference` DESC
LIMIT 3;