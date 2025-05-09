-- 5 states with the most storm events (1980-1995), keeping only
-- the 1 000 highest-count states in each individual year
WITH yearly_state_counts AS (
  SELECT
    _TABLE_SUFFIX                AS yr,
    UPPER(state)                 AS state_abbrev,
    COUNT(*)                     AS yearly_events,
    DENSE_RANK() OVER (PARTITION BY _TABLE_SUFFIX
                       ORDER BY COUNT(*) DESC) AS rnk
  FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE _TABLE_SUFFIX BETWEEN '1980' AND '1995'
  GROUP BY yr, state_abbrev
),
top_states_each_year AS (
  SELECT *
  FROM yearly_state_counts
  WHERE rnk <= 1000              -- keep only the 1 000 most-active states per year
)
SELECT
  state_abbrev,
  SUM(yearly_events) AS total_events_1980_1995
FROM top_states_each_year
GROUP BY state_abbrev
ORDER BY total_events_1980_1995 DESC
LIMIT 5;