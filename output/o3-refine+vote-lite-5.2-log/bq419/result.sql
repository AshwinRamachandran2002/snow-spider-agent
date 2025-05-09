-- Top 5 states (abbreviations) with the most storm events, 1980‑1995
WITH events AS (
  SELECT
    CAST(_TABLE_SUFFIX AS INT64)          AS year,
    UPPER(TRIM(state))                   AS state
  FROM
    `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '1980' AND '1995'      -- years of interest
    AND state IS NOT NULL
),
yearly_counts AS (                          -- events per state per year
  SELECT
    year,
    state,
    COUNT(*) AS event_cnt
  FROM events
  WHERE LENGTH(state) = 2                   -- keep 2‑letter abbreviations
  GROUP BY year, state
),
ranked AS (                                 -- rank states within each year
  SELECT
    year, state, event_cnt,
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY event_cnt DESC) AS rn
  FROM yearly_counts
),
top_states AS (                             -- top 1000 states each year
  SELECT year, state, event_cnt
  FROM ranked
  WHERE rn <= 1000
),
overall AS (                                -- aggregate across all years
  SELECT
    state,
    SUM(event_cnt) AS total_events
  FROM top_states
  GROUP BY state
)
SELECT
  state,
  total_events
FROM overall
ORDER BY total_events DESC
LIMIT 5;