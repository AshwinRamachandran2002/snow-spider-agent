WITH all_events AS (
  SELECT
    _TABLE_SUFFIX AS yr,
    state
  FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE _TABLE_SUFFIX BETWEEN '1980' AND '1995'
    AND state IS NOT NULL
),
yearly_counts AS (
  SELECT
    yr,
    state,
    COUNT(*) AS event_cnt
  FROM all_events
  GROUP BY yr, state
),
ranked AS (
  SELECT
    yr,
    state,
    event_cnt,
    ROW_NUMBER() OVER (PARTITION BY yr ORDER BY event_cnt DESC) AS rn
  FROM yearly_counts
)
SELECT
  state,
  SUM(event_cnt) AS total_storm_events
FROM ranked
WHERE rn <= 1000
GROUP BY state
ORDER BY total_storm_events DESC, state
LIMIT 5;