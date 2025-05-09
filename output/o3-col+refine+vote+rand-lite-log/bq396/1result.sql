-- Top 3 states with the largest difference between rainy and clear-weather crashes
-- on weekends (Saturday/Sunday) in 2016
SELECT
  state_name AS state,
  ABS(rain_weekend_crashes - clear_weekend_crashes) AS difference_rain_vs_clear
FROM (
  -- Weekend clear-weather crashes per state
  SELECT
    clr.state_name,
    clr.clear_weekend_crashes,
    IFNULL(rn.rain_weekend_crashes, 0) AS rain_weekend_crashes
  FROM (
    SELECT
      state_name,
      COUNT(*) AS clear_weekend_crashes
    FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
    WHERE day_of_week IN (1, 7)                         -- 1 = Sunday, 7 = Saturday
      AND LOWER(atmospheric_conditions_1_name) = 'clear'
    GROUP BY state_name
  ) AS clr
  LEFT JOIN (
    SELECT
      state_name,
      COUNT(*) AS rain_weekend_crashes
    FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
    WHERE day_of_week IN (1, 7)
      AND LOWER(atmospheric_conditions_1_name) = 'rain'
    GROUP BY state_name
  ) AS rn
  USING (state_name)
)
ORDER BY difference_rain_vs_clear DESC
LIMIT 3;