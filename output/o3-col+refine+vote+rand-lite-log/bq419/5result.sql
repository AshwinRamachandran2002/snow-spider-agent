WITH yearly AS (
  -- 1. Count how many storm events each state had in every year 1980-1995
  SELECT
    _TABLE_SUFFIX AS year,
    UPPER(state) AS state_abbr,
    COUNT(*)     AS events
  FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE _TABLE_SUFFIX BETWEEN '1980' AND '1995'
  GROUP BY year, state_abbr
),
ranked AS (
  -- 2. Rank states within each year by their event count
  SELECT
    year,
    state_abbr,
    events,
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY events DESC) AS rn
  FROM yearly
)
-- 3. Keep states that fall within the yearly top-1000,
--    sum their events across all years, and return the top-5 overall
SELECT
  state_abbr,
  SUM(events) AS total_events_1980_1995
FROM ranked
WHERE rn <= 1000
GROUP BY state_abbr
ORDER BY total_events_1980_1995 DESC
LIMIT 5;