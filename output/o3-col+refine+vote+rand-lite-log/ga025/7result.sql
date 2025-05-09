/*  Percentage of Sept-2018 first-open users who uninstalled ≤7 days
    and, within the same 7-day window, experienced at least one crash  */
WITH first_open AS (   -- all Sept-2018 first-opens
  SELECT
    user_pseudo_id,
    DATE(TIMESTAMP_MICROS(event_timestamp)) AS first_open_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20180930'
    AND event_name = 'first_open'
),
uninstalls AS (        -- all uninstalls up to 7 days after Sept
  SELECT
    user_pseudo_id,
    DATE(TIMESTAMP_MICROS(event_timestamp)) AS uninstall_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20181007'
    AND event_name = 'app_remove'
),
crashes AS (           -- all crashes in the same period
  SELECT
    user_pseudo_id,
    DATE(TIMESTAMP_MICROS(event_timestamp)) AS crash_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20181007'
    AND event_name = 'app_exception'
),
uninstall_7d AS (      -- users who uninstalled within 0-7 days of first-open
  SELECT DISTINCT
    f.user_pseudo_id,
    f.first_open_date
  FROM first_open  AS f
  JOIN uninstalls AS u USING (user_pseudo_id)
  WHERE DATE_DIFF(u.uninstall_date, f.first_open_date, DAY) BETWEEN 0 AND 7
),
uninstall_7d_with_crash AS (   -- of those, who also crashed in same 7-day window
  SELECT DISTINCT
    u.user_pseudo_id
  FROM uninstall_7d u
  JOIN crashes      c USING (user_pseudo_id)
  WHERE DATE_DIFF(c.crash_date, u.first_open_date, DAY) BETWEEN 0 AND 7
)
SELECT
  (SELECT COUNT(*) FROM uninstall_7d_with_crash) AS users_with_crash,
  (SELECT COUNT(*) FROM uninstall_7d)            AS uninstall_7d_users,
  SAFE_DIVIDE(
      (SELECT COUNT(*) FROM uninstall_7d_with_crash),
      (SELECT COUNT(*) FROM uninstall_7d)
  )                                             AS crash_percentage
;