WITH state_year_counts AS (
  SELECT
    _TABLE_SUFFIX AS year,
    UPPER(state)      AS state,
    COUNT(*)          AS event_cnt
  FROM
    `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '1980' AND '1995'
    AND state IS NOT NULL
    AND state <> ''
  GROUP BY
    year, state
),
ranked AS (
  SELECT
    year,
    state,
    event_cnt,
    RANK() OVER (PARTITION BY year ORDER BY event_cnt DESC) AS rnk
  FROM
    state_year_counts
),
filtered AS (
  -- keep only the top 1000 states (effectively all states, but per requirement)
  SELECT
    year, state, event_cnt
  FROM
    ranked
  WHERE
    rnk <= 1000
),
state_totals AS (
  SELECT
    state,
    SUM(event_cnt) AS total_events
  FROM
    filtered
  GROUP BY
    state
)
SELECT
  state,
  total_events
FROM
  state_totals
ORDER BY
  total_events DESC
LIMIT 5;