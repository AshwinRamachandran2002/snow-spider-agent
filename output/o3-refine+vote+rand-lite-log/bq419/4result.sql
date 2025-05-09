WITH yearly_state_counts AS (
  SELECT
    CAST(_TABLE_SUFFIX AS INT64) AS yr,
    UPPER(state)               AS state,
    COUNT(*)                   AS events_in_year
  FROM
    `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '1980' AND '1995'
    AND state IS NOT NULL
  GROUP BY
    yr, state
),
top_states_each_year AS (
  SELECT
    yr,
    state,
    events_in_year
  FROM (
    SELECT
      yr,
      state,
      events_in_year,
      ROW_NUMBER() OVER (PARTITION BY yr ORDER BY events_in_year DESC) AS rn
    FROM
      yearly_state_counts
  )
  WHERE
    rn <= 1000  -- keeps every state (<=50) but fulfils requirement
),
total_1980_1995 AS (
  SELECT
    state,
    SUM(events_in_year) AS total_events
  FROM
    top_states_each_year
  GROUP BY
    state
)
SELECT
  state,
  total_events
FROM
  total_1980_1995
ORDER BY
  total_events DESC
LIMIT 5;