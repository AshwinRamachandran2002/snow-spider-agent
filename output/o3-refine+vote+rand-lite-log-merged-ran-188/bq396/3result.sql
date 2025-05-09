WITH weekend_weather AS (
  SELECT
    state_name,
    atmospheric_conditions_1_name AS weather,
    COUNT(*) AS crash_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
  WHERE year_of_crash = 2016
    AND day_of_week IN (1, 7)                             -- 1 = Sunday, 7 = Saturday
    AND atmospheric_conditions_1_name IN ('Clear', 'Rain')
  GROUP BY state_name, weather
),
pivot AS (
  SELECT
    state_name,
    MAX(CASE WHEN weather = 'Clear' THEN crash_cnt END) AS clear_cnt,
    MAX(CASE WHEN weather = 'Rain'  THEN crash_cnt END) AS rain_cnt
  FROM weekend_weather
  GROUP BY state_name
)
SELECT
  state_name,
  ABS(rain_cnt - clear_cnt) AS difference_between_rain_and_clear
FROM pivot
ORDER BY difference_between_rain_and_clear DESC
LIMIT 3;