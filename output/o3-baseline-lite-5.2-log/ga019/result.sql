-- % of users who installed during Aug–Sep 2018 and EITHER
-- (a) never un‑installed, OR (b) first un‑installed more than 7 days after install
WITH first_install AS (          -- initial install (first_open) in Aug & Sep 2018
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS install_ts               -- micro‑seconds
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
    AND event_name = 'first_open'
  GROUP BY user_pseudo_id
),
first_uninstall AS (             -- first uninstall (app_remove) seen up to 3 Oct 2018
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS uninstall_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20181003'
    AND event_name = 'app_remove'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM first_install)
  GROUP BY user_pseudo_id
),
cohort AS (
  SELECT
    fi.user_pseudo_id,
    fi.install_ts,
    fu.uninstall_ts
  FROM first_install fi
  LEFT JOIN first_uninstall fu
  USING (user_pseudo_id)
)
SELECT
  ROUND(
    100 * COUNTIF( uninstall_ts IS NULL                          -- never uninstalled
                   OR (uninstall_ts - install_ts) / 1e6 / 86400 > 7 )   -- or after 7d
        / COUNT(*), 
    4) AS pct_users_no_uninstall_within_7d
FROM cohort;