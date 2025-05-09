WITH weekend_weather AS (
  SELECT
    state_name,
    CASE
      WHEN atmospheric_conditions_1_name = 'Rain'
           OR atmospheric_conditions_2_name = 'Rain'
           OR atmospheric_conditions_name   = 'Rain'
        THEN 'Rain'
      WHEN atmospheric_conditions_1_name = 'Clear'
           OR atmospheric_conditions_2_name = 'Clear'
           OR atmospheric_conditions_name   = 'Clear'
        THEN 'Clear'
      ELSE NULL
    END AS weather_cat
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
  -- 1 = Sunday, 7 = Saturday in FARS coding
  WHERE day_of_week IN (1, 7)          -- weekend only
),

weather_counts AS (
  SELECT
    state_name,
    SUM(CASE WHEN weather_cat = 'Rain'  THEN 1 ELSE 0 END)  AS rainy_accidents,
    SUM(CASE WHEN weather_cat = 'Clear' THEN 1 ELSE 0 END)  AS clear_accidents
  FROM weekend_weather
  WHERE weather_cat IS NOT NULL
  GROUP BY state_name
),

differences AS (
  SELECT
    state_name,
    rainy_accidents,
    clear_accidents,
    ABS(rainy_accidents - clear_accidents) AS difference
  FROM weather_counts
)

SELECT
  state_name,
  difference
FROM differences
ORDER BY difference DESC
LIMIT 3;