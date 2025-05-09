-- Top 3 states with the largest difference between weekend RAIN and CLEAR crashes in 2016
WITH clear AS (
  SELECT
    state_name,
    COUNT(*) AS clear_accidents
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
  WHERE day_of_week IN (1,7)                 -- 1 = Sunday, 7 = Saturday
    AND atmospheric_conditions_1_name = 'Clear'
  GROUP BY state_name
),
rain AS (
  SELECT
    state_name,
    COUNT(*) AS rain_accidents
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
  WHERE day_of_week IN (1,7)
    AND atmospheric_conditions_1_name = 'Rain'
  GROUP BY state_name
)
SELECT
  COALESCE(r.state_name, c.state_name) AS state_name,
  COALESCE(r.rain_accidents, 0)          AS rain_accidents,
  COALESCE(c.clear_accidents, 0)         AS clear_accidents,
  ABS(COALESCE(r.rain_accidents, 0) -
      COALESCE(c.clear_accidents, 0))    AS difference
FROM rain r
FULL OUTER JOIN clear c USING (state_name)
ORDER BY difference DESC
LIMIT 3;