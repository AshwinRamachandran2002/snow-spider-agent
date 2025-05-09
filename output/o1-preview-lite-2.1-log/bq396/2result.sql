SELECT
  state_name AS State,
  ABS(
    COUNTIF(atmospheric_conditions_1 = 1 OR atmospheric_conditions_2 = 1)
    - COUNTIF(atmospheric_conditions_1 = 0 OR atmospheric_conditions_2 = 0)
  ) AS Difference
FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
WHERE day_of_week IN (1, 7)
GROUP BY State
ORDER BY Difference DESC
LIMIT 3