-- 5 states with the most storm events (1980-1995) after applying the “top-1000-per-year” rule
WITH yr_state_counts AS (
  SELECT
    _TABLE_SUFFIX AS yr,
    state,
    COUNT(*) AS event_cnt
  FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE _TABLE_SUFFIX BETWEEN '1980' AND '1995'
  GROUP BY yr, state
),
yr_state_ranked AS (
  SELECT
    yr,
    state,
    event_cnt,
    ROW_NUMBER() OVER (PARTITION BY yr ORDER BY event_cnt DESC) AS rn
  FROM yr_state_counts
),
agg AS (
  SELECT
    state,
    SUM(event_cnt) AS total_events_80_95
  FROM yr_state_ranked
  WHERE rn <= 1000            -- keep only the top-1000 states each year
  GROUP BY state
)
SELECT
  state
FROM agg
ORDER BY total_events_80_95 DESC
LIMIT 5;