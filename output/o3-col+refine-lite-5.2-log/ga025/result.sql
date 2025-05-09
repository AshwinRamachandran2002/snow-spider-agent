/*  Percentage of September‑2018 first‑open users who uninstalled within 7 days
    and experienced at least one crash (app_exception) before that uninstall   */

WITH first_open AS (           -- earliest first_open in Sep‑2018 per user
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_open_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20180930'
    AND event_name = 'first_open'
  GROUP BY user_pseudo_id
),

uninstalls AS (                -- earliest uninstall (app_remove) after first open
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS uninstall_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20181007'
    AND event_name = 'app_remove'
  GROUP BY user_pseudo_id
),

crashes AS (                   -- first crash (app_exception) per user
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS crash_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20181007'
    AND event_name = 'app_exception'
  GROUP BY user_pseudo_id
),

qualified AS (                 -- users who uninstalled within 7 days of 1st open
  SELECT
    f.user_pseudo_id,
    f.first_open_date,
    u.uninstall_date,
    c.crash_date
  FROM first_open  f
  JOIN uninstalls  u ON f.user_pseudo_id = u.user_pseudo_id
  LEFT JOIN crashes c ON f.user_pseudo_id = c.user_pseudo_id
  WHERE DATE_DIFF(u.uninstall_date, f.first_open_date, DAY) BETWEEN 0 AND 7
)

SELECT
  COUNT(DISTINCT user_pseudo_id)                                                   AS total_uninstalls_within_7d,
  COUNT(DISTINCT CASE
                   WHEN crash_date IS NOT NULL
                    AND crash_date <= uninstall_date THEN user_pseudo_id
                 END)                                                             AS uninstalls_with_crash,
  SAFE_DIVIDE(
      COUNT(DISTINCT CASE
                       WHEN crash_date IS NOT NULL
                        AND crash_date <= uninstall_date THEN user_pseudo_id
                     END),
      COUNT(DISTINCT user_pseudo_id)
  ) * 100                                                                          AS pct_with_crash
FROM qualified;