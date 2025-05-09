-- user with the longest numbered month (from their first activity) who later became inactive
WITH base AS (               -- keep only data up to 2024‑09‑10 and convert to year‑month
  SELECT
    `by`                      AS user_id,
    DATE_TRUNC( DATE(timestamp), MONTH ) AS activity_month
  FROM `bigquery-public-data.hacker_news.full`
  WHERE timestamp < TIMESTAMP '2024-09-11'   -- up‑to (and excluding) 2024‑09‑11
    AND `by` IS NOT NULL                     -- need a valid user name
),

per_user AS (                -- first/last month and how many distinct months they posted
  SELECT
    user_id,
    MIN(activity_month)                       AS first_month,
    MAX(activity_month)                       AS last_month,
    COUNT(DISTINCT activity_month)            AS active_months
  FROM base
  GROUP BY user_id
),

eligible AS (                -- keep users who have: (1) at least one gap month, (2) stopped before Sept‑2024
  SELECT
    user_id,
    DATE_DIFF(last_month, first_month, MONTH) + 1 AS span_months     -- numbered months (1‑based)
  FROM per_user
  WHERE active_months < (DATE_DIFF(last_month, first_month, MONTH) + 1)        -- internal gap exists
    AND last_month < DATE '2024-09-01'                                          -- no activity in/after Sept‑2024
)

SELECT
  user_id,
  span_months AS month_number             -- month number counted from first activity month
FROM eligible
ORDER BY span_months DESC, user_id        -- highest numbered month, tie‑break by user_id
LIMIT 1;