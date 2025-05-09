-- Percentage of September‑2018 new users who uninstalled in ≤7 days
-- and experienced at least one crash (app_exception) before that uninstall
WITH events AS (
  -- Pull only the days we need: 1‑Sep‑2018 … 7‑Oct‑2018
  SELECT
    user_pseudo_id,
    DATE(TIMESTAMP_MICROS(user_first_touch_timestamp))        AS first_open_date,
    event_name,
    DATE(TIMESTAMP_MICROS(event_timestamp))                   AS event_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20181007'        -- YYYYMMDD
),

-- Users whose very first open occurred in September‑2018
sept_first_open AS (
  SELECT DISTINCT user_pseudo_id, first_open_date
  FROM events
  WHERE first_open_date BETWEEN '2018-09-01' AND '2018-09-30'
),

-- Each user’s earliest uninstall (app_remove) date
uninstalls AS (
  SELECT user_pseudo_id, MIN(event_date) AS uninstall_date
  FROM events
  WHERE event_name = 'app_remove'
  GROUP BY user_pseudo_id
),

-- First crash (app_exception) date for each user
crashes AS (
  SELECT user_pseudo_id, MIN(event_date) AS crash_date
  FROM events
  WHERE event_name = 'app_exception'
  GROUP BY user_pseudo_id
),

-- Users who opened in Sept‑2018 and uninstalled within 7 days
target_users AS (
  SELECT
    s.user_pseudo_id,
    s.first_open_date,
    u.uninstall_date
  FROM sept_first_open s
  JOIN uninstalls      u ON u.user_pseudo_id = s.user_pseudo_id
  WHERE DATE_DIFF(u.uninstall_date, s.first_open_date, DAY) <= 7
)

SELECT
  COUNTIF( c.crash_date BETWEEN t.first_open_date AND t.uninstall_date )        AS users_with_crash,
  COUNT(*)                                                                      AS total_uninstalled_within_7d,
  SAFE_DIVIDE(
    COUNTIF( c.crash_date BETWEEN t.first_open_date AND t.uninstall_date ),
    COUNT(*)
  ) * 100                                                                       AS crash_percentage
FROM target_users t
LEFT JOIN crashes c
  ON c.user_pseudo_id = t.user_pseudo_id;