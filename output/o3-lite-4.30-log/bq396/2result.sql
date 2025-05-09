WITH rain AS (
  SELECT
    state_name AS state,
    COUNT(*)   AS rain_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
  WHERE day_of_week IN (1,7)  -- weekend
    AND (LOWER(atmospheric_conditions_1_name) LIKE '%rain%'
         OR LOWER(atmospheric_conditions_2_name) LIKE '%rain%')
  GROUP BY state
),
clear AS (
  SELECT
    state_name AS state,
    COUNT(*)   AS clear_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
  WHERE day_of_week IN (1,7)  -- weekend
    AND (LOWER(atmospheric_conditions_1_name) LIKE '%clear%'
         OR LOWER(atmospheric_conditions_2_name) LIKE '%clear%')
  GROUP BY state
)
SELECT
  COALESCE(r.state, c.state)                                                AS state,
  CAST(ABS(IFNULL(r.rain_cnt,0) - IFNULL(c.clear_cnt,0)) AS INT64)          AS difference
FROM rain r
FULL OUTER JOIN clear c USING (state)
ORDER BY difference DESC, state
LIMIT 3;