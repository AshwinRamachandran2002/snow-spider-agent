-- Top 5 U.S. state abbreviations with the most severe–storm events
-- from 1980 through 1995 (inclusive), after considering only the
-- 1,000 most‑active states in each individual year.

WITH yearly_state_counts AS (
  SELECT
    CAST(_TABLE_SUFFIX AS INT64)       AS year,
    UPPER(state)                       AS state,
    COUNT(*)                           AS event_cnt
  FROM
    `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '1980' AND '1995'         -- years of interest
    AND state IS NOT NULL                           -- exclude missing codes
  GROUP BY
    year, state
),
top_states_each_year AS (                         -- keep only top‑1000 per year
  SELECT *
  FROM (
    SELECT
      year,
      state,
      event_cnt,
      ROW_NUMBER() OVER (PARTITION BY year
                         ORDER BY event_cnt DESC, state) AS rn
    FROM yearly_state_counts
  )
  WHERE rn <= 1000
)
SELECT
  state,
  SUM(event_cnt) AS total_events_1980_1995
FROM
  top_states_each_year
GROUP BY
  state
ORDER BY
  total_events_1980_1995 DESC
LIMIT 5;