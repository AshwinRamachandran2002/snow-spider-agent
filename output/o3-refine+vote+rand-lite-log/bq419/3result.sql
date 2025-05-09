-- 5 states with the highest number of storm events (1980‑1995)
-- considering only states that fall within the top‑1000 for each year
WITH yearly_state_counts AS (
  SELECT
    CAST(_TABLE_SUFFIX AS INT64) AS year,
    UPPER(state)                 AS state,
    COUNT(*)                     AS event_count
  FROM
    `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE
    SAFE_CAST(_TABLE_SUFFIX AS INT64) BETWEEN 1980 AND 1995
    AND state IS NOT NULL
  GROUP BY
    year, state
),
ranked_states AS (
  SELECT
    year,
    state,
    event_count,
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY event_count DESC) AS rn
  FROM
    yearly_state_counts
)
SELECT
  state,
  SUM(event_count) AS total_events_1980_1995
FROM
  ranked_states
WHERE
  rn <= 1000          -- keep only the top 1000 states each year
GROUP BY
  state
ORDER BY
  total_events_1980_1995 DESC
LIMIT 5;