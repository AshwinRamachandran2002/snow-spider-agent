-- User(s) whose first month of post–inactivity (the month that follows
-- their final recorded activity month) occurs at the largest month-number
-- since their very first activity, provided they already have at least
-- one “hole” (a month with no activity) inside the span from first→last.
WITH month_log AS (      -- 1.  User-month activity register
  SELECT
    `by`                                   AS user_id ,
    DATE_TRUNC(DATE(`timestamp`), MONTH)   AS activity_month
  FROM `bigquery-public-data.hacker_news.full`
  WHERE `by` IS NOT NULL
    AND `timestamp` < '2024-09-11'               -- only data up-to 10-Sep-2024
),
agg AS (              -- 2.  First / last month + full list of active months
  SELECT
    user_id ,
    MIN(activity_month)                                            AS first_month ,
    MAX(activity_month)                                            AS last_month  ,
    ARRAY_AGG(DISTINCT activity_month ORDER BY activity_month)      AS months_active
  FROM month_log
  GROUP BY user_id
),
holes AS (            -- 3.  Detect any missing month(s) inside the span
  SELECT
    *,
    ARRAY(
      SELECT m
      FROM UNNEST(GENERATE_DATE_ARRAY(first_month, last_month, INTERVAL 1 MONTH)) AS m
      WHERE m NOT IN UNNEST(months_active)
    ) AS missing_inside_span
  FROM agg
),
ranked AS (           -- 4.  Month-number (from first month) where inactivity starts
  SELECT
    user_id ,
    1 + TIMESTAMP_DIFF(DATE_ADD(last_month, INTERVAL 1 MONTH), first_month, MONTH)
        AS month_number_at_inactivity          -- month immediately after last activity
  FROM holes
  WHERE ARRAY_LENGTH(missing_inside_span) > 0  -- keep only users that have at least one hole
)
-- 5.  Return the user(s) with the largest month-number at which they became inactive
SELECT
  user_id ,
  month_number_at_inactivity
FROM ranked
QUALIFY RANK() OVER (ORDER BY month_number_at_inactivity DESC) = 1;