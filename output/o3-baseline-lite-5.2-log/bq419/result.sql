-- 5 states with the highest total number of historic severe–storm events
-- (1980‑1995), considering only the 1 000 most‑active states each year
WITH yearly_state_counts AS (
  SELECT
    CAST(_TABLE_SUFFIX AS INT64) AS year,
    UPPER(state)               AS state,
    COUNT(*)                   AS events
  FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE
    CAST(_TABLE_SUFFIX AS INT64) BETWEEN 1980 AND 1995   -- years of interest
    AND state IS NOT NULL                               -- skip missing states
  GROUP BY year, state
),
top_states_each_year AS (       -- keep only top‑1 000 states per year
  SELECT *
  FROM (
    SELECT
      year,
      state,
      events,
      ROW_NUMBER() OVER (PARTITION BY year ORDER BY events DESC) AS rn
    FROM yearly_state_counts
  )
  WHERE rn <= 1000              -- effectively all states, but keeps logic explicit
),
state_totals AS (               -- accumulate events across all years
  SELECT
    state,
    SUM(events) AS total_events
  FROM top_states_each_year
  GROUP BY state
)
SELECT
  state,
  total_events
FROM state_totals
ORDER BY total_events DESC
LIMIT 5;