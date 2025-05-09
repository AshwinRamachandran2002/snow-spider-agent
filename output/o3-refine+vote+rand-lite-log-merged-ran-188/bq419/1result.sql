WITH per_state_year AS (
  -- count events for each state in every year
  SELECT
    _TABLE_SUFFIX AS year,
    UPPER(TRIM(state)) AS state,
    COUNT(*) AS event_count
  FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE _TABLE_SUFFIX BETWEEN '1980' AND '1995'          -- years of interest
    AND state IS NOT NULL
    AND TRIM(state) <> ''
  GROUP BY year, state
),
ranked AS (
  -- rank states by event count within each year
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY year
                       ORDER BY event_count DESC, state) AS rn
  FROM per_state_year
),
top1000 AS (
  -- keep only the top‑1000 states per year (all states will qualify, but keeps logic explicit)
  SELECT *
  FROM ranked
  WHERE rn <= 1000
),
aggregate_state AS (
  -- sum events across 1980‑1995 for the retained states
  SELECT
    state,
    SUM(event_count) AS total_events
  FROM top1000
  GROUP BY state
)
-- final 5 states with the most storm events
SELECT
  state,
  total_events
FROM aggregate_state
ORDER BY total_events DESC, state
LIMIT 5;