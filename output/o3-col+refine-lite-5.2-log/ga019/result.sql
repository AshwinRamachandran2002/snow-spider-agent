-- Percentage of Aug‑Sep 2018 installers who either
-- (a) never uninstalled, or (b) uninstalled only after 7+ days
WITH installs AS (
  SELECT user_pseudo_id,
         MIN(event_timestamp) AS install_ts                -- first_open
  FROM  `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
    AND event_name = 'first_open'
  GROUP BY user_pseudo_id
),
removes AS (
  SELECT user_pseudo_id,
         MIN(event_timestamp) AS uninstall_ts              -- app_remove
  FROM  `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
    AND event_name = 'app_remove'
  GROUP BY user_pseudo_id
)
SELECT
  ROUND(
    100 * COUNTIF( uninstall_ts IS NULL                           -- never uninstalled
                   OR (uninstall_ts - install_ts) > 7*24*3600*1e6 -- uninstalled after 7 days
                 )
    / COUNT(*), 4)                                                -- keep 4 decimals
    AS pct_users_retained_7_days_plus
FROM installs
LEFT JOIN removes USING (user_pseudo_id);