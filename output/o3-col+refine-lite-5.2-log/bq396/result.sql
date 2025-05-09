/* Top‑3 states with the greatest absolute gap between the number of
   weekend crashes that occurred in CLEAR vs. RAIN weather during 2016 */

WITH weekend_weather AS (
  SELECT
    state_name,
    SUM(CASE WHEN atmospheric_conditions_1_name = 'Clear' THEN 1 ELSE 0 END) AS clear_cnt,
    SUM(CASE WHEN atmospheric_conditions_1_name = 'Rain'  THEN 1 ELSE 0 END) AS rain_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
  -- 1 = Sunday, 7 = Saturday
  WHERE day_of_week IN (1, 7)
  GROUP BY state_name
),
diffs AS (
  SELECT
    state_name,
    clear_cnt,
    rain_cnt,
    ABS(clear_cnt - rain_cnt) AS difference
  FROM weekend_weather
)
SELECT
  state_name,
  difference
FROM diffs
ORDER BY difference DESC, state_name
LIMIT 3;