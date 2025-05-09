-- 5 states with the most storm events (1980‑1995)  
-- considering only the 1 000 highest‑count states for each year
WITH yearly_state_counts AS (
  SELECT
    CAST(_TABLE_SUFFIX AS INT64) AS yr,
    UPPER(state)                AS state,
    COUNT(*)                    AS event_cnt
  FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE _TABLE_SUFFIX BETWEEN '1980' AND '1995'   -- years of interest
    AND state IS NOT NULL
  GROUP BY yr, state
),
ranked AS (
  SELECT
    yr,
    state,
    event_cnt,
    ROW_NUMBER() OVER (PARTITION BY yr ORDER BY event_cnt DESC, state) AS rn
  FROM yearly_state_counts
),
top_1000_per_year AS (
  SELECT yr, state, event_cnt
  FROM ranked
  WHERE rn <= 1000               -- keep only the top 1 000 states each year
)
SELECT
  state,
  SUM(event_cnt) AS total_events
FROM top_1000_per_year
GROUP BY state
ORDER BY total_events DESC, state
LIMIT 5;