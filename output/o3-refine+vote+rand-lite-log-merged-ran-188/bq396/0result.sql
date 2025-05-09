WITH weekend_crashes AS (
  SELECT
    state_name,
    LOWER(atmospheric_conditions_1_name) AS weather
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
  WHERE day_of_week IN (1, 7)                 -- 1 = Sunday, 7 = Saturday
),

rain AS (
  SELECT state_name, COUNT(*) AS rain_crashes
  FROM weekend_crashes
  WHERE weather = 'rain'
  GROUP BY state_name
),

clear AS (
  SELECT state_name, COUNT(*) AS clear_crashes
  FROM weekend_crashes
  WHERE weather = 'clear'
  GROUP BY state_name
)

SELECT
  COALESCE(c.state_name, r.state_name)                           AS state_name,
  IFNULL(clear_crashes, 0)                                       AS clear_crashes,
  IFNULL(rain_crashes, 0)                                        AS rain_crashes,
  ABS(IFNULL(clear_crashes, 0) - IFNULL(rain_crashes, 0)) AS difference
FROM clear AS c
FULL JOIN rain AS r
USING (state_name)
ORDER BY difference DESC
LIMIT 3;