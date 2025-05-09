/* user with the longest numbered month (since first activity) who later went inactive */
WITH user_months AS (
  /* keep one row per user per calendar month up to 2024‑09‑10 */
  SELECT
    `by`                             AS user_id,
    DATE_TRUNC(DATE(`timestamp`), MONTH) AS month_date
  FROM `bigquery-public-data.hacker_news.full`
  WHERE `by` IS NOT NULL
    AND `timestamp` < TIMESTAMP('2024-09-11')          -- consider data through 10‑Sep‑2024
),
user_stats AS (
  SELECT
    user_id,
    MIN(month_date)                          AS first_month,
    MAX(month_date)                          AS last_month,
    COUNT(DISTINCT month_date)               AS active_months              -- highest month number
  FROM user_months
  GROUP BY user_id
),
qualified_users AS (
  SELECT
    user_id,
    active_months,
    1 + TIMESTAMP_DIFF(last_month, first_month, MONTH) AS expected_months
  FROM user_stats
  WHERE
        -- at least one gap month inside the user’s active span
        1 + TIMESTAMP_DIFF(last_month, first_month, MONTH) > active_months
    AND -- user has been inactive since at least September 2024
        last_month < DATE '2024-09-01'
)
SELECT
  user_id,
  active_months AS month_number               -- month number counting from first active month
FROM qualified_users
ORDER BY active_months DESC, user_id
LIMIT 1;