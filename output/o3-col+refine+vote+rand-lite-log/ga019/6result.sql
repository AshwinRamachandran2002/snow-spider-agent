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
combined AS (
  SELECT
    i.user_pseudo_id,
    DATE_DIFF(
      DATE(TIMESTAMP_MICROS(u.uninstall_ts)),
      DATE(TIMESTAMP_MICROS(i.install_ts)),
      DAY
    ) AS days_to_uninstall
  FROM installs i
  LEFT JOIN uninstalls u
  ON i.user_pseudo_id = u.user_pseudo_id
)
SELECT
  ROUND(
    100 * SUM(CASE
                WHEN days_to_uninstall IS NULL OR days_to_uninstall > 7 THEN 1
                ELSE 0
              END) / COUNT(*),
    4
  ) AS pct_users_not_uninstall_within_7d
FROM combined;