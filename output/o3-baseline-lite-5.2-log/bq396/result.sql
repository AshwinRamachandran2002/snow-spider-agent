--  Top 3 states with the greatest absolute difference between
--  weekend crashes that happened in clear vs. rainy weather, 2016
WITH weekend_weather AS (
  SELECT
    state_name,
    -- “Rain” is coded 2 in FARS; count a crash as rainy if
    -- either of the two reported weather codes is 2.
    COUNTIF(atmospheric_conditions_1 = 2
            OR atmospheric_conditions_2 = 2)               AS rainy_cnt,
    -- “Clear” is coded 1; count a crash as clear if either
    -- weather code is 1.
    COUNTIF(atmospheric_conditions_1 = 1
            OR atmospheric_conditions_2 = 1)               AS clear_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
  -- weekend crashes only (1 = Sunday, 7 = Saturday)
  WHERE day_of_week IN (1, 7)
  GROUP BY state_name
),
diffs AS (
  SELECT
    state_name,
    rainy_cnt,
    clear_cnt,
    ABS(rainy_cnt - clear_cnt) AS diff_cnt
  FROM weekend_weather
)
SELECT
  state_name,
  diff_cnt AS difference_between_rainy_and_clear
FROM diffs
ORDER BY diff_cnt DESC, state_name
LIMIT 3;