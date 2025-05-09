WITH rain AS (
  SELECT
    state_name AS state,
    COUNT(*)   AS rain_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
  WHERE year_of_crash = 2016
    AND day_of_week IN (1,7)  -- Sunday = 1, Saturday = 7
    AND (LOWER(atmospheric_conditions_1_name) LIKE '%rain%'
         OR LOWER(atmospheric_conditions_2_name) LIKE '%rain%')
  GROUP BY state_name
),
clear AS (
  SELECT
    state_name AS state,
    COUNT(*)   AS clear_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
  WHERE year_of_crash = 2016
    AND day_of_week IN (1,7)
    AND (atmospheric_conditions_1_name = 'Clear'
         OR atmospheric_conditions_2_name = 'Clear')
  GROUP BY state_name
)
SELECT
  COALESCE(r.state, c.state)                                AS state,
  ABS(COALESCE(r.rain_cnt, 0) - COALESCE(c.clear_cnt, 0))   AS difference
FROM rain r
FULL JOIN clear c
ON r.state = c.state
ORDER BY difference DESC, state
LIMIT 3;