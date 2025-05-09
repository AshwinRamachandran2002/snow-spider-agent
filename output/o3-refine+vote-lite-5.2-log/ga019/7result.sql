/*  Percentage of users that either
    – never uninstalled, or
    – uninstalled more than 7 days after installing,
    among users whose first install happened in Aug–Sep 2018                */

WITH installs AS (        -- installs that happened in Aug‑Sep 2018
  SELECT
      user_pseudo_id,
      MIN(event_timestamp) AS install_ts        -- first time the user opened the app
  FROM  `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
    AND event_name = 'first_open'
  GROUP BY user_pseudo_id
),

uninstalls AS (           -- earliest uninstall seen (allowing for 7‑day window into Oct)
  SELECT
      user_pseudo_id,
      MIN(event_timestamp) AS uninstall_ts
  FROM  `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20181007'   -- covers 7‑day window after 30 Sep
    AND event_name = 'app_remove'
  GROUP BY user_pseudo_id
),

evaluation AS (
  SELECT
      i.user_pseudo_id,
      i.install_ts,
      u.uninstall_ts,
      CASE
        WHEN u.uninstall_ts IS NULL                                   -- never uninstalled
             OR u.uninstall_ts > i.install_ts + 604800000000          -- more than 7 days (μs)
        THEN 1 ELSE 0
      END AS kept_flag
  FROM installs i
  LEFT JOIN uninstalls u USING (user_pseudo_id)
)

SELECT
    COUNTIF(kept_flag = 1)            AS users_not_uninstalled_within_7d_or_never,
    COUNT(*)                          AS total_installed_users,
    ROUND(COUNTIF(kept_flag = 1) * 100.0 / COUNT(*), 4) AS percentage_users
FROM evaluation;