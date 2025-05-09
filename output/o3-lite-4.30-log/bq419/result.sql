/* 5 states with the most storm events (1980‑1995) –
   counting only states that were in the top‑1000 for each individual year */
WITH unioned AS (
  -- read all yearly tables at once and keep only 1980‑1995
  SELECT
    CAST(_TABLE_SUFFIX AS INT64)     AS yr,
    UPPER(state)                     AS state_abbr
  FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE _TABLE_SUFFIX BETWEEN '1980' AND '1995'
),
yearly_counts AS (
  -- number of events per state and year
  SELECT
    yr,
    state_abbr,
    COUNT(*) AS events_in_year
  FROM unioned
  GROUP BY yr, state_abbr
),
ranked AS (
  -- rank states by event count within each year
  SELECT
    yr,
    state_abbr,
    events_in_year,
    RANK() OVER (PARTITION BY yr ORDER BY events_in_year DESC) AS rnk
  FROM yearly_counts
),
top1k AS (
  -- keep only the 1 000 highest‑count states per year
  SELECT *
  FROM ranked
  WHERE rnk <= 1000
)
-- final aggregation across all years
SELECT
  state_abbr AS state,
  SUM(events_in_year) AS total_storm_events
FROM top1k
GROUP BY state
ORDER BY total_storm_events DESC, state
LIMIT 5;