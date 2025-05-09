SELECT
  state_name AS state,
  ABS(
    SUM(CASE WHEN LOWER(atmospheric_conditions_1_name) = 'clear' THEN 1 ELSE 0 END) -
    SUM(CASE WHEN LOWER(atmospheric_conditions_1_name) = 'rain'  THEN 1 ELSE 0 END)
  ) AS difference
FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
WHERE day_of_week IN (1, 7)                       -- weekends (Sunday & Saturday)
  AND LOWER(atmospheric_conditions_1_name) IN ('clear', 'rain')  -- limit to clear or rain
GROUP BY state
ORDER BY difference DESC, state
LIMIT 3;