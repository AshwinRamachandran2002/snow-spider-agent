/*  Percentage of September‑2018 new users (first_open)
    who un‑installed within seven days and, before that
    uninstall, experienced at least one crash (app_exception)  */

WITH events AS (
  SELECT
    user_pseudo_id,
    event_name,
    -- event time & date in the user’s locale
    TIMESTAMP_MICROS(event_timestamp)                       AS event_ts,
    DATE(TIMESTAMP_MICROS(event_timestamp))                 AS event_dt
  FROM `firebase-public-project.analytics_153293282.events_*`
  /*  need data from Sept‑2018 and the following week (up to 7‑Oct‑2018) */
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20181007'
    AND event_name IN ('first_open','app_remove','app_exception')
),

/* first time the app was opened */
first_open AS (
  SELECT
    user_pseudo_id,
    MIN(event_dt) AS first_open_dt
  FROM events
  WHERE event_name = 'first_open'
  GROUP BY user_pseudo_id
  HAVING first_open_dt BETWEEN '2018-09-01' AND '2018-09-30'
),

/* earliest uninstall */
uninstall AS (
  SELECT
    user_pseudo_id,
    MIN(event_dt) AS uninstall_dt
  FROM events
  WHERE event_name = 'app_remove'
  GROUP BY user_pseudo_id
),

/* whether user ever had an app crash (before uninstall) */
crash AS (
  SELECT
    fo.user_pseudo_id,
    COUNT(*) > 0 AS has_crash
  FROM first_open  fo
  JOIN events      e
    ON fo.user_pseudo_id = e.user_pseudo_id
  JOIN uninstall   u
    ON fo.user_pseudo_id = u.user_pseudo_id
  WHERE e.event_name = 'app_exception'
    AND e.event_dt BETWEEN fo.first_open_dt AND u.uninstall_dt   -- crash happened before uninstall
  GROUP BY fo.user_pseudo_id
),

/* bring all info together */
user_summary AS (
  SELECT
    fo.user_pseudo_id,
    fo.first_open_dt,
    u.uninstall_dt,
    DATE_DIFF(u.uninstall_dt, fo.first_open_dt, DAY) AS days_to_uninstall,
    IFNULL(c.has_crash, FALSE)                       AS has_crash
  FROM first_open fo
  JOIN uninstall  u  ON fo.user_pseudo_id = u.user_pseudo_id
  LEFT JOIN crash c  ON fo.user_pseudo_id = c.user_pseudo_id
)

SELECT
  COUNTIF(has_crash)                                        AS users_with_crash,
  COUNT(*)                                                  AS total_users_uninstalled_within_7_days,
  SAFE_DIVIDE(COUNTIF(has_crash), COUNT(*)) * 100 AS crash_percentage
FROM user_summary
WHERE days_to_uninstall BETWEEN 0 AND 7;   -- ≤ 7 calendar days