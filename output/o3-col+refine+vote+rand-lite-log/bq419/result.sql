-- 5 states with the most severe–storm events (1980-1995)  
-- keeping only the top-1000 states for each year before aggregation
WITH yearly AS (
  SELECT
    _TABLE_SUFFIX AS yr,
    UPPER(state)      AS state_abbrev,
    COUNT(*)          AS events
  FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE _TABLE_SUFFIX BETWEEN '1980' AND '1995'
  GROUP BY yr, state_abbrev
),
ranked AS (
  SELECT
    yr,
    state_abbrev,
    events,
    RANK() OVER (PARTITION BY yr ORDER BY events DESC) AS rnk
  FROM yearly
)
SELECT
  state_abbrev,
  SUM(events) AS total_events_1980_1995
FROM ranked
WHERE rnk <= 1000          -- keep only the yearly top-1000 states
GROUP BY state_abbrev
ORDER BY total_events_1980_1995 DESC
LIMIT 5;