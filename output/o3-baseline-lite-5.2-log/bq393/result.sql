-- user with the longest counted activity span (in months) that contains at least
-- one internal month with no activity and who shows no activity after the last
-- recorded active month (up to 2024‑09‑10)
WITH activity_per_month AS (
  SELECT
    `by`                     AS user_id,
    DATE_TRUNC(DATE(`timestamp`), MONTH) AS activity_month
  FROM
    `bigquery-public-data.hacker_news.full`
  WHERE
    `timestamp` < TIMESTAMP('2024-09-11')   -- consider data up to 2024‑09‑10 (inclusive)
    AND `by` IS NOT NULL                    -- ignore deleted / anonymous
),
user_month_stats AS (
  SELECT
    user_id,
    MIN(activity_month)                                                    AS first_month,
    MAX(activity_month)                                                    AS last_month,
    COUNT(DISTINCT activity_month)                                         AS active_month_cnt,
    DATE_DIFF(MAX(activity_month), MIN(activity_month), MONTH) + 1         AS month_number  -- months since first activity
  FROM activity_per_month
  GROUP BY user_id
),
qualified_users AS (
  SELECT *
  FROM   user_month_stats
  WHERE  month_number > active_month_cnt      -- at least one missing month inside [first_month, last_month]
)
SELECT
  user_id,
  month_number
FROM qualified_users
ORDER BY month_number DESC, user_id
LIMIT 1;