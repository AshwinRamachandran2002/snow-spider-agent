WITH installs AS (
  -- Earliest install (first_open) for every user in Aug–Sep 2018
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS install_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
    AND event_name = 'first_open'
  GROUP BY user_pseudo_id
),
uninstalls AS (
  -- Earliest uninstall (app_remove) for the same period
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS first_uninstall_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
    AND event_name = 'app_remove'
  GROUP BY user_pseudo_id
),
user_lifecycle AS (
  -- Combine install and uninstall info
  SELECT
    i.user_pseudo_id,
    i.install_ts,
    u.first_uninstall_ts
  FROM installs AS i
  LEFT JOIN uninstalls AS u
  USING (user_pseudo_id)
)
-- Percentage who never uninstalled or uninstalled only after 7 days
SELECT
  SAFE_DIVIDE(
      SUM(
        CASE
          WHEN first_uninstall_ts IS NULL                      -- never uninstalled
               OR first_uninstall_ts > install_ts + 604800000000  -- after 7 days (7*24*60*60*1e6 µs)
          THEN 1
        END),
      COUNT(*)
  ) * 100 AS pct_users_not_uninstall_within_7days
FROM user_lifecycle;