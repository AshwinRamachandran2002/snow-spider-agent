-- Top 3 states with the largest weekend difference between clear- and rainy-weather crashes in 2016
WITH clear AS (
  SELECT
    state_name,
    COUNT(*) AS clear_count
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
  WHERE day_of_week IN (1, 7)          -- 1 = Sunday, 7 = Saturday
    AND atmospheric_conditions_1 = 1   -- 1 = Clear
  GROUP BY state_name
),
rain AS (
  SELECT
    state_name,
    COUNT(*) AS rain_count
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
  WHERE day_of_week IN (1, 7)
    AND atmospheric_conditions_1 = 2   -- 2 = Rain
  GROUP BY state_name
)
SELECT
  COALESCE(c.state_name, r.state_name)            AS state_name,
  IFNULL(c.clear_count, 0)                        AS clear_count,
  IFNULL(r.rain_count , 0)                        AS rain_count,
  ABS(IFNULL(r.rain_count,0) - IFNULL(c.clear_count,0)) AS difference
FROM clear c
FULL JOIN rain r
ON c.state_name = r.state_name
ORDER BY difference DESC
LIMIT 3;