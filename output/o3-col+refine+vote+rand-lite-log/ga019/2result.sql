WITH installs AS (
  -- first time the app was opened (install moment) per user
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS first_open_ts
  FROM
    `firebase-public-project.analytics_153293282.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
    AND event_name = 'first_open'
  GROUP BY
    user_pseudo_id
),
uninstalls AS (
  -- first time the app was removed (un-install moment) per user
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS first_uninstall_ts
  FROM
    `firebase-public-project.analytics_153293282.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
    AND event_name = 'app_remove'
  GROUP BY
    user_pseudo_id
),
survival_flag AS (
  -- mark users who never uninstalled or uninstalled after day-7
  SELECT
    i.user_pseudo_id,
    IF(
      u.first_uninstall_ts IS NULL
      OR (u.first_uninstall_ts - i.first_open_ts) > 7*86400*1e6,
      1,                               -- survived 7 days (or never uninstalled)
      0                                -- uninstalled within 7 days
    ) AS survived_7d_or_never
  FROM
    installs i
  LEFT JOIN
    uninstalls u
  USING (user_pseudo_id)
)
SELECT
  SUM(survived_7d_or_never) AS users_survived_7d_or_never,
  COUNT(*)                  AS total_installs,
  ROUND(100 * SUM(survived_7d_or_never) / COUNT(*), 4) AS pct_survived_7d_or_never
FROM
  survival_flag;