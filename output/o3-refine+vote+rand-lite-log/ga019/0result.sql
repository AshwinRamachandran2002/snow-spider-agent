/*  Users that installed in Aug‑Sep 2018 and
    (a) never triggered an uninstall  OR
    (b) triggered their first uninstall more than 7 days after install
    ------------------------------------------------------------------ */
WITH

/* 1. Installs that happened during August & September 2018            */
installs AS (
  SELECT
      user_pseudo_id,
      MIN(event_timestamp) AS install_ts          -- first install in period
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'   -- tables for Aug‑Sep
    AND event_name = 'first_open'                        -- install event
    AND user_pseudo_id IS NOT NULL
  GROUP BY user_pseudo_id
),

/* 2. First uninstall AFTER the install (if any)                       */
uninstalls AS (
  SELECT
      i.user_pseudo_id,
      MIN(e.event_timestamp) AS uninstall_ts           -- earliest uninstall
  FROM installs i
  JOIN `firebase-public-project.analytics_153293282.events_*` e
    ON  e.user_pseudo_id = i.user_pseudo_id
  WHERE e.event_name = 'app_remove'
    AND e.event_timestamp >= i.install_ts              -- must be after install
    AND _TABLE_SUFFIX BETWEEN '20180801' AND '20181003' -- include days needed
  GROUP BY i.user_pseudo_id
),

/* 3. Flag users that did NOT uninstall within 7 days                  */
evaluation AS (
  SELECT
      i.user_pseudo_id,
      CASE
          WHEN u.uninstall_ts IS NULL                              -- never uninstalled
               OR u.uninstall_ts > i.install_ts + 7*24*60*60*1000000
          THEN 1                                                   -- kept app ≥7 days
          ELSE 0                                                   -- uninstalled ≤7 days
      END AS kept_flag
  FROM installs   i
  LEFT JOIN uninstalls u
    ON u.user_pseudo_id = i.user_pseudo_id
)

/* 4. Percentage of “kept” users                                      */
SELECT
    ROUND(100 * SUM(kept_flag) / COUNT(*), 4) AS pct_users_kept_7d
FROM evaluation;