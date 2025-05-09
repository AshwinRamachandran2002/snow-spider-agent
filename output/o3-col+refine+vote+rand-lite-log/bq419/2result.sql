-- 5 states with the most storm events 1980-1995 (only states in yearly top-1000 kept)
WITH events AS (
  SELECT
    CAST(SUBSTR(_TABLE_SUFFIX, 1, 4) AS INT64) AS yr,
    state
  FROM
    `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '1980' AND '1995'          -- years of interest
    AND state IS NOT NULL                            -- safety filter
),
yearly_counts AS (
  SELECT
    yr,
    state,
    COUNT(*) AS cnt
  FROM events
  GROUP BY yr, state
),
ranked AS (                                                -- rank states within each year
  SELECT
    yr,
    state,
    cnt,
    ROW_NUMBER() OVER (PARTITION BY yr ORDER BY cnt DESC) AS rn
  FROM yearly_counts
),
top_per_year AS (                                          -- keep only top-1000 per year
  SELECT yr, state, cnt
  FROM ranked
  WHERE rn <= 1000
),
totals AS (                                                -- aggregate across years
  SELECT
    state,
    SUM(cnt) AS total_cnt
  FROM top_per_year
  GROUP BY state
)
SELECT
  state,
  total_cnt
FROM totals
ORDER BY total_cnt DESC
LIMIT 5;