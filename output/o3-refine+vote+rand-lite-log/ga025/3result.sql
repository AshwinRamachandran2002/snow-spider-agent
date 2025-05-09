/*  Percentage of September‑2018 first‑open users who un‑installed within
    seven days AND, inside that same 7‑day window, experienced an
    application crash (event_name = 'app_exception').               */

WITH events AS (
  -- keep only uninstall & crash rows for the period we need
  SELECT
    user_pseudo_id,
    DATE(TIMESTAMP_MICROS(user_first_touch_timestamp))             AS first_open_date,
    event_name,
    PARSE_DATE('%Y%m%d', event_date)                               AS evt_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20181007'
    AND event_name IN ('app_remove', 'app_exception')
),
sept_first_open_users AS (
  -- users whose very first open happened in September‑2018
  SELECT DISTINCT user_pseudo_id, first_open_date
  FROM events
  WHERE first_open_date BETWEEN '2018-09-01' AND '2018-09-30'
),
uninstall_dates AS (
  -- earliest uninstall (app_remove) per user
  SELECT user_pseudo_id, MIN(evt_date) AS uninstall_date
  FROM events
  WHERE event_name = 'app_remove'
  GROUP BY user_pseudo_id
),
crash_dates AS (
  -- earliest crash (app_exception) per user
  SELECT user_pseudo_id, MIN(evt_date) AS crash_date
  FROM events
  WHERE event_name = 'app_exception'
  GROUP BY user_pseudo_id
),
combined AS (
  -- join everything together
  SELECT
    u.user_pseudo_id,
    u.first_open_date,
    un.uninstall_date,
    cr.crash_date
  FROM sept_first_open_users u
  LEFT JOIN uninstall_dates un USING (user_pseudo_id)
  LEFT JOIN crash_dates     cr USING (user_pseudo_id)
),
totals AS (
  -- denominator: un‑installs ≤ 7 days after first‑open
  -- numerator   : those un‑installs that also had a crash in the same 7‑day window
  SELECT
    COUNTIF(
      uninstall_date IS NOT NULL
      AND uninstall_date <= DATE_ADD(first_open_date, INTERVAL 7 DAY)
    )                                                               AS uninstall_7d,

    COUNTIF(
      uninstall_date IS NOT NULL
      AND uninstall_date <= DATE_ADD(first_open_date, INTERVAL 7 DAY)
      AND crash_date IS NOT NULL
      AND crash_date BETWEEN first_open_date
                         AND DATE_ADD(first_open_date, INTERVAL 7 DAY)
    )                                                               AS uninstall_7d_with_crash
  FROM combined
)

SELECT
  uninstall_7d_with_crash,
  uninstall_7d,
  SAFE_DIVIDE(uninstall_7d_with_crash, uninstall_7d) * 100 AS percent_with_crash
FROM totals;