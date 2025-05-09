-- Top 3 states with the greatest differences between weekend crashes
-- that happened in clear vs. rainy weather during 2016
WITH weekend_weather AS (
  SELECT
    state_name,
    -- crashes whose primary weather condition is “Clear”
    SUM(CASE WHEN atmospheric_conditions_1_name = 'Clear' THEN 1 ELSE 0 END) AS clear_cnt,
    -- crashes whose primary weather condition is “Rain”
    SUM(CASE WHEN atmospheric_conditions_1_name = 'Rain'  THEN 1 ELSE 0 END) AS rain_cnt
  FROM
    `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
  -- 1 = Sunday, 7 = Saturday in FARS coding
  WHERE
    day_of_week IN (1, 7)
  GROUP BY
    state_name
)
SELECT
  state_name,
  clear_cnt,
  rain_cnt,
  ABS(clear_cnt - rain_cnt) AS difference
FROM
  weekend_weather
ORDER BY
  difference DESC
LIMIT 3;