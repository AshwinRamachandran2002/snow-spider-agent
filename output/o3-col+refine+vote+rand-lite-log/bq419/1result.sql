-- 5 states with the most storm events (1980-1995) after restricting
-- each year to its 1,000 most-active states
WITH yearly AS (
  SELECT
    _TABLE_SUFFIX AS year,
    UPPER(state)  AS state,
    COUNT(*)      AS events_in_year
  FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE _TABLE_SUFFIX BETWEEN '1980' AND '1995'
  GROUP BY year, state
),
top1k AS (
  SELECT *
  FROM yearly
  QUALIFY RANK() OVER (PARTITION BY year ORDER BY events_in_year DESC) <= 1000
)
SELECT
  state,
  SUM(events_in_year) AS total_events_1980_1995
FROM top1k
GROUP BY state
ORDER BY total_events_1980_1995 DESC
LIMIT 5;