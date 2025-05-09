-- 5 states with the most storm events (1980‑1995) – only states that fall
-- within the top‑1000 by event count for each individual year are considered.
WITH events AS (
  SELECT
    CAST(_TABLE_SUFFIX AS INT64) AS yr,
    UPPER(TRIM(state))        AS state
  FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE _TABLE_SUFFIX BETWEEN '1980' AND '1995'
    AND state IS NOT NULL
),
yearly_state_counts AS (
  SELECT
    yr,
    state,
    COUNT(*) AS event_cnt
  FROM events
  GROUP BY yr, state
),
top_states_each_year AS (
  SELECT
    yr,
    state,
    event_cnt
  FROM (
    SELECT
      yr,
      state,
      event_cnt,
      ROW_NUMBER() OVER (PARTITION BY yr ORDER BY event_cnt DESC) AS rn
    FROM yearly_state_counts
  )
  WHERE rn <= 1000            -- keep only top 1000 states per year
)
SELECT
  state,
  SUM(event_cnt) AS total_events_1980_1995
FROM top_states_each_year
GROUP BY state
ORDER BY total_events_1980_1995 DESC
LIMIT 5;