WITH installs AS (
  -- first time each user installed (Aug-01 to Sep-30 2018)
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS install_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
    AND event_name = 'first_open'
  GROUP BY user_pseudo_id
),
uninstalls AS (
  -- first time each user un-installed (within same two-month window)
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS uninstall_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
    AND event_name = 'app_remove'
  GROUP BY user_pseudo_id
)

SELECT
  COUNT(DISTINCT i.user_pseudo_id) AS total_installs,
  COUNTIF(
        u.uninstall_ts IS NULL                          -- never uninstalled
     OR (u.uninstall_ts - i.install_ts) > 7*86400*1e6   -- uninstalled after 7 days
  ) AS kept_7d_or_more,
  ROUND(
    100 * COUNTIF(
           u.uninstall_ts IS NULL
        OR (u.uninstall_ts - i.install_ts) > 7*86400*1e6
    )
    / COUNT(DISTINCT i.user_pseudo_id)
  , 2) AS pct_kept_7d_or_more
FROM installs i
LEFT JOIN uninstalls u
ON i.user_pseudo_id = u.user_pseudo_id;