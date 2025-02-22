-- Task: List the top 3 states with the largest absolute differences between the number of traffic accidents that occurred during 'Rain' and 'Clear' weather conditions on weekends (days of week 1 and 7) in 2016. Only consider accidents where the atmospheric condition was 'Rain' or 'Clear'. Provide the differences for each state.
SELECT
  "state_name",
  ABS(
    SUM(CASE WHEN "atmospheric_conditions_1_name" = 'Rain' THEN 1 ELSE 0 END) -
    SUM(CASE WHEN "atmospheric_conditions_1_name" = 'Clear' THEN 1 ELSE 0 END)
  ) AS "Difference"
FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2016
WHERE
  "day_of_week" IN (1, 7)
  AND "atmospheric_conditions_1_name" IN ('Rain', 'Clear')
GROUP BY "state_name"
ORDER BY "Difference" DESC NULLS LAST
LIMIT 3;