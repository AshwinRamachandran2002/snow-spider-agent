-- Top-3 states with the largest absolute difference between
-- weekend (“Saturday” or “Sunday”) fatal-crash counts that happened in
-- “Rain” versus “Clear” weather during 2016.
SELECT
  state_name AS state,
  ABS(
    SUM(CASE WHEN LOWER(atmospheric_conditions_1_name) = 'rain'  THEN 1 ELSE 0 END) -
    SUM(CASE WHEN LOWER(atmospheric_conditions_1_name) = 'clear' THEN 1 ELSE 0 END)
  ) AS difference
FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
WHERE day_of_week IN (1, 7)            -- 1 = Sunday, 7 = Saturday
GROUP BY state
ORDER BY difference DESC
LIMIT 3;