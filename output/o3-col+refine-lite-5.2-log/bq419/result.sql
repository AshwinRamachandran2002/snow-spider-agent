-- 5 states with the most severe–storm events (1980‑1995),
-- counting only the 1 000 highest‑volume states each year
WITH year_state_counts AS (
  SELECT
    _TABLE_SUFFIX           AS yr,
    UPPER(TRIM(state))      AS state_abbrev,
    COUNT(*)                AS events_in_state_year
  FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE _TABLE_SUFFIX BETWEEN '1980' AND '1995'
  GROUP BY yr, state_abbrev
),
yearly_top_1000 AS (
  SELECT
    yr,
    state_abbrev,
    events_in_state_year,
    ROW_NUMBER() OVER (PARTITION BY yr
                       ORDER BY events_in_state_year DESC) AS rnk
  FROM year_state_counts
)
SELECT
  state_abbrev,
  SUM(events_in_state_year) AS total_events_1980_1995
FROM yearly_top_1000
WHERE rnk <= 1000
GROUP BY state_abbrev
ORDER BY total_events_1980_1995 DESC
LIMIT 5;