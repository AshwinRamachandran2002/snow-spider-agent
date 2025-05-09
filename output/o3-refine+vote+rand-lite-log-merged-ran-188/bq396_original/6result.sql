WITH weekend_weather AS (
  SELECT
    state_name,
    CASE
      WHEN atmospheric_conditions_1_name = 'Rain'  THEN 'Rain'
      WHEN atmospheric_conditions_1_name = 'Clear' THEN 'Clear'
    END AS weather
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
  WHERE
    day_of_week IN (1, 7)                                -- 1 = Sunday, 7 = Saturday
    AND atmospheric_conditions_1_name IN ('Rain','Clear') -- keep only Rain / Clear crashes
)

SELECT
  state_name,
  SUM(CASE WHEN weather = 'Rain'  THEN 1 ELSE 0 END) AS rainy_accidents,
  SUM(CASE WHEN weather = 'Clear' THEN 1 ELSE 0 END) AS clear_accidents,
  ABS(
      SUM(CASE WHEN weather = 'Rain'  THEN 1 ELSE 0 END) -
      SUM(CASE WHEN weather = 'Clear' THEN 1 ELSE 0 END)
  ) AS difference
FROM weekend_weather
GROUP BY state_name
ORDER BY difference DESC
LIMIT 3;