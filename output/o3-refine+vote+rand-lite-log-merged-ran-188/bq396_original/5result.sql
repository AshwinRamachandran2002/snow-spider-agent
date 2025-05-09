-- Top 3 states with the largest weekend (Sat/Sun) difference between
-- rainy and clear‑weather traffic accidents in 2016
WITH weekend_accidents AS (
  SELECT
    state_name,
    CASE
      WHEN 'Rain'  IN UNNEST([atmospheric_conditions_1_name,
                              atmospheric_conditions_2_name,
                              atmospheric_conditions_name]) THEN 'Rain'
      WHEN 'Clear' IN UNNEST([atmospheric_conditions_1_name,
                              atmospheric_conditions_2_name,
                              atmospheric_conditions_name]) THEN 'Clear'
      ELSE 'Other'
    END AS weather
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
  -- 1 = Sunday, 7 = Saturday in the FARS coding
  WHERE day_of_week IN (1, 7)
)

SELECT
  state_name,
  SUM(CASE WHEN weather = 'Rain'  THEN 1 ELSE 0 END) AS rainy_accidents,
  SUM(CASE WHEN weather = 'Clear' THEN 1 ELSE 0 END) AS clear_accidents,
  ABS(SUM(CASE WHEN weather = 'Rain'  THEN 1 ELSE 0 END) -
      SUM(CASE WHEN weather = 'Clear' THEN 1 ELSE 0 END)) AS difference
FROM weekend_accidents
WHERE weather IN ('Rain', 'Clear')          -- keep only relevant records
GROUP BY state_name
ORDER BY difference DESC
LIMIT 3;