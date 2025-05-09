WITH first_open AS (      -- Sept-2018 first opens
  SELECT
    user_pseudo_id,
    MIN(DATE(TIMESTAMP_MICROS(event_timestamp))) AS first_open_date
  FROM `firebase-public-project.analytics_153293282.events_201809*`
  WHERE event_name = 'first_open'
  GROUP BY user_pseudo_id
),
uninstall AS (            -- first uninstall (allow early-Oct for 7-day window)
  SELECT
    user_pseudo_id,
    MIN(DATE(TIMESTAMP_MICROS(event_timestamp))) AS uninstall_date
  FROM (
        SELECT * FROM `firebase-public-project.analytics_153293282.events_201809*`
        UNION ALL
        SELECT * FROM `firebase-public-project.analytics_153293282.events_201810*`
       )
  WHERE event_name = 'app_remove'
  GROUP BY user_pseudo_id
),
crash AS (                -- users who crashed in Sept-2018
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_201809*`
  WHERE event_name = 'app_exception'
)
SELECT
  ROUND(
    100 * SAFE_DIVIDE(
      COUNT(DISTINCT CASE WHEN c.user_pseudo_id IS NOT NULL
                          THEN q.user_pseudo_id END),
      COUNT(DISTINCT q.user_pseudo_id)
    ),
    2
  ) AS pct_uninstall_with_crash
FROM (
      SELECT fo.user_pseudo_id, fo.first_open_date, u.uninstall_date
      FROM first_open fo
      JOIN uninstall  u USING (user_pseudo_id)
      WHERE DATE_DIFF(u.uninstall_date, fo.first_open_date, DAY) <= 7
     ) AS q               -- users who uninstalled within 7 days
LEFT JOIN crash c
       USING (user_pseudo_id);