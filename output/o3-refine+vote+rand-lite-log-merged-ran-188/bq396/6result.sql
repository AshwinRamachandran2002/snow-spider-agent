SELECT
  state_name,
  ABS(
        SUM(CASE WHEN atmospheric_conditions_1_name = 'Rain'
                  OR atmospheric_conditions_2_name = 'Rain'  THEN 1 ELSE 0 END)
      - SUM(CASE WHEN atmospheric_conditions_1_name = 'Clear'
                  OR atmospheric_conditions_2_name = 'Clear' THEN 1 ELSE 0 END)
  ) AS difference
FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
WHERE day_of_week IN (1,7)           -- 1 = Sunday, 7 = Saturday
GROUP BY state_name
ORDER BY difference DESC
LIMIT 3;