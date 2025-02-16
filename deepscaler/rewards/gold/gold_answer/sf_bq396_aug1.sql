-- Task: Which states had the highest number of traffic accidents during weekends in 2016 when the atmospheric condition was 'Rain'? Provide the number of accidents for each state.
SELECT
  "state_name",
  COUNT(*) AS "Rain_Accidents"
FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2016
WHERE
  "day_of_week" IN (1, 7)
  AND "atmospheric_conditions_1_name" = 'Rain'
GROUP BY "state_name"
ORDER BY "Rain_Accidents" DESC NULLS LAST;