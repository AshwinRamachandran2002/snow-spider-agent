-- 5 states with the greatest number of storm events (1980-1995),
-- counting events only when the state is within that year’s top-1000
WITH all_years AS (
  SELECT
    CAST(_TABLE_SUFFIX AS INT64) AS yr,
    state
  FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE _TABLE_SUFFIX BETWEEN '1980' AND '1995'
),
ranked AS (
  SELECT
    yr,
    state,
    COUNT(*) AS yr_state_events,
    RANK() OVER (PARTITION BY yr ORDER BY COUNT(*) DESC) AS rk
  FROM all_years
  GROUP BY yr, state
),
top1000 AS (
  SELECT
    yr,
    state,
    yr_state_events
  FROM ranked
  WHERE rk <= 1000          -- keep only states in each year’s top-1000
),
totals AS (
  SELECT
    state,
    SUM(yr_state_events) AS total_events_1980_1995
  FROM top1000
  GROUP BY state
)
SELECT
  state,
  total_events_1980_1995
FROM totals
ORDER BY total_events_1980_1995 DESC
LIMIT 5;