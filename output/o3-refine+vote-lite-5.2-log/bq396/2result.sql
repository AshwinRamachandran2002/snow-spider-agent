WITH weekend_accidents AS (
  SELECT
    state_name,
    CASE
      /* “3” is Rain, “1” is Clear in FARS coding.
         Treat a crash as Rainy if either atmospheric condition field = 3.
         Treat as Clear if the first condition = 1 and the second is 0 or NULL.
         All other weather is ignored. */
      WHEN 3 IN (atmospheric_conditions_1, atmospheric_conditions_2) THEN 'Rain'
      WHEN atmospheric_conditions_1 = 1
           AND (atmospheric_conditions_2 = 0 OR atmospheric_conditions_2 IS NULL) THEN 'Clear'
      ELSE NULL
    END AS weather_type
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
  /* 1 = Sunday, 7 = Saturday in the FARS day‑of‑week coding */
  WHERE day_of_week IN (1, 7)
),

state_weather_counts AS (
  SELECT
    state_name,
    SUM(CASE WHEN weather_type = 'Rain'  THEN 1 ELSE 0 END) AS rainy_accidents,
    SUM(CASE WHEN weather_type = 'Clear' THEN 1 ELSE 0 END) AS clear_accidents
  FROM weekend_accidents
  WHERE weather_type IS NOT NULL            -- keep only Rain or Clear rows
  GROUP BY state_name
),

state_differences AS (
  SELECT
    state_name,
    ABS(clear_accidents - rainy_accidents) AS difference
  FROM state_weather_counts
)

SELECT
  state_name,
  difference
FROM state_differences
ORDER BY difference DESC
LIMIT 3;