WITH weekend_weather_counts AS (
  SELECT
    state_name,
    COUNTIF(atmospheric_conditions_1_name = 'Clear') AS clear_weekend_accidents,
    COUNTIF(atmospheric_conditions_1_name = 'Rain')  AS rain_weekend_accidents
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
  WHERE day_of_week IN (1,7)             -- 1 = Sunday, 7 = Saturday
  GROUP BY state_name
)
SELECT
  state_name,
  clear_weekend_accidents,
  rain_weekend_accidents,
  ABS(clear_weekend_accidents - rain_weekend_accidents) AS difference
FROM weekend_weather_counts
ORDER BY difference DESC
LIMIT 3;