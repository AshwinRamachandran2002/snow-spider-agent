/* -----------------------------------------------------------
   Identify the user who stayed active for the largest number
   of months (counted from their first‑ever active month) and
   later became inactive.

   Conditions
   1.  Data considered only up to 10‑Sep‑2024 (exclusive).
   2.  The user must have at least one “gap month” inside the
       span from first to last activity (i.e., total span
       months > distinct active months).
   3.  The user must have no activity in the cut‑off month
       2024‑09 (meaning their last active month is ≤ 2024‑08).

   Output
   • user_id      – the Hacker News user name (`by` column)
   • month_number – how many months the user stayed active,
                    numbered from 1 at their first active month
------------------------------------------------------------ */
WITH activity_by_month AS (
  SELECT
    `by`                              AS user_id,
    DATE_TRUNC(DATE(timestamp), MONTH) AS activity_month
  FROM `bigquery-public-data.hacker_news.full`
  WHERE
        timestamp < TIMESTAMP '2024-09-11'      -- up to 10‑Sep‑2024 23:59:59
    AND `by` IS NOT NULL                        -- ignore rows without a user
  GROUP BY
    user_id, activity_month                     -- one row per user‑month
),
user_month_stats AS (                           -- first, last and counts
  SELECT
    user_id,
    MIN(activity_month)                    AS first_month,
    MAX(activity_month)                    AS last_month,
    COUNT(*)                               AS active_months_cnt           -- distinct already
  FROM activity_by_month
  GROUP BY user_id
),
qualified_users AS (                           -- enforce gap & inactivity
  SELECT
    user_id,
    -- months are numbered starting at 1
    DATE_DIFF(last_month, first_month, MONTH) + 1 AS month_number,
    active_months_cnt
  FROM user_month_stats
  WHERE
        -- at least one missing month inside the span
        DATE_DIFF(last_month, first_month, MONTH) + 1 > active_months_cnt
    -- no activity in 2024‑09 (i.e., inactive after last recorded month)
    AND last_month < DATE '2024-09-01'
)
SELECT
  user_id,
  month_number
FROM qualified_users
ORDER BY
  month_number DESC,          -- highest month number first
  user_id                     -- deterministic tie‑breaker
LIMIT 1;