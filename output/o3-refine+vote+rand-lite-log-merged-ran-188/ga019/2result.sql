/*  Percentage of users that installed during Aug‑Sep 2018
    who did NOT uninstall the app inside the first seven days  
    (i.e. they either uninstalled after 7 days or have never uninstalled) */

WITH installs AS (         -- all installs in Aug & Sep 2018
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS install_ts          -- first install in period
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
    AND event_name = 'first_open'
  GROUP BY user_pseudo_id
),

uninstalls AS (            -- earliest uninstall AFTER the install
  SELECT
    i.user_pseudo_id,
    MIN(e.event_timestamp) AS uninstall_ts
  FROM installs AS i
  JOIN `firebase-public-project.analytics_153293282.events_*` AS e
    ON e.user_pseudo_id = i.user_pseudo_id
  WHERE e.event_name = 'app_remove'
    AND e.event_timestamp >= i.install_ts        -- only consider uninstalls after that install
  GROUP BY i.user_pseudo_id
),

results AS (
  SELECT
    i.user_pseudo_id,
    i.install_ts,
    u.uninstall_ts,
    CASE
      WHEN u.uninstall_ts IS NOT NULL
           AND u.uninstall_ts <= i.install_ts + 604800000000  -- 7 days in µs
      THEN 1            -- uninstalled within 7 days
      ELSE 0            -- did NOT uninstall within 7 days (or never)
    END AS removed_within_7_days
  FROM installs AS i
  LEFT JOIN uninstalls AS u
  ON i.user_pseudo_id = u.user_pseudo_id
)

SELECT
  ROUND(100 * SUM(1 - removed_within_7_days) / COUNT(*), 4) AS pct_not_removed_within_7_or_never
FROM results;