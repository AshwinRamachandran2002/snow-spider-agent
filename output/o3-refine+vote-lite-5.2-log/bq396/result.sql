WITH weekend_accidents AS (
  SELECT
    state_name,
    CASE
      WHEN atmospheric_conditions_1_name = 'Rain'
           OR atmospheric_conditions_2_name = 'Rain' THEN 'Rain'
      WHEN atmospheric_conditions_1_name = 'Clear'
           OR atmospheric_conditions_name  = 'Clear'  THEN 'Clear'
      ELSE NULL                      -- ignore other / unknown weather
    END AS weather
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
  WHERE day_of_week IN (1,7)         -- 1 = Sunday, 7 = Saturday
),

state_weather_counts AS (
  SELECT
    state_name,
    SUM(CASE WHEN weather = 'Rain'  THEN 1 ELSE 0 END) AS rain_accidents,
    SUM(CASE WHEN weather = 'Clear' THEN 1 ELSE 0 END) AS clear_accidents
  FROM weekend_accidents
  WHERE weather IS NOT NULL
  GROUP BY state_name
)

SELECT
  state_name,
  ABS(rain_accidents - clear_accidents) AS difference_in_accidents
FROM state_weather_counts
ORDER BY difference_in_accidents DESC
LIMIT 3;