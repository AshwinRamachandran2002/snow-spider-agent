-- Percentage of Aug-Sep-2018 installers who
-- (a) never uninstalled OR (b) uninstalled only after ≥7 days
WITH installs AS (          -- all installs in Aug-Sep 2018
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS install_ts          -- first install moment
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
    AND event_name = 'first_open'
  GROUP BY user_pseudo_id
),
uninstalls AS (             -- earliest uninstall for every user
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS uninstall_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20181031'   -- look a bit past Sept
    AND event_name = 'app_remove'
  GROUP BY user_pseudo_id
),
stats AS (                  -- count totals & “good” users
  SELECT
    COUNT(*) AS total_installed_users,
    COUNTIF(
        uninstall_ts IS NULL                                 -- never uninstalled
        OR (uninstall_ts - install_ts) > 7*24*60*60*1e6      -- uninstalled after 7 days
    ) AS good_users
  FROM installs i
  LEFT JOIN uninstalls u USING (user_pseudo_id)
)
SELECT
  ROUND(good_users / total_installed_users * 100, 2) AS pct_good_users
FROM stats;