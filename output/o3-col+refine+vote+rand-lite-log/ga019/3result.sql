-- Percentage of users who either never uninstalled or uninstalled after 7 days
WITH installs AS (
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS install_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
    AND event_name = 'first_open'
  GROUP BY user_pseudo_id
),
uninstalls AS (
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS uninstall_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
    AND event_name = 'app_remove'
  GROUP BY user_pseudo_id
),
flags AS (
  SELECT
    i.user_pseudo_id,
    CASE
      WHEN u.uninstall_ts IS NULL                            THEN 'kept_app_7plus'
      WHEN u.uninstall_ts - i.install_ts <= 604800000000     THEN 'uninstall_within_7d'
      ELSE                                                        'kept_app_7plus'
    END AS status_flag
  FROM installs i
  LEFT JOIN uninstalls u USING (user_pseudo_id)
)
SELECT
  ROUND(COUNTIF(status_flag = 'kept_app_7plus') * 100.0 / COUNT(*), 4) AS pct_kept_app_7plus
FROM flags;