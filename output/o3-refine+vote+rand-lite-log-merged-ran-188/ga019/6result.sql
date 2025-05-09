-- percentage of users who did NOT uninstall within 7 days (or never uninstalled)
WITH installs AS (     -- first‑time installs that happened in Aug‑Sep 2018
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS install_ts          -- micro‑seconds since epoch
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
    AND event_name = 'first_open'
  GROUP BY user_pseudo_id
),
uninstalls AS (        -- earliest uninstall observed for each user
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS uninstall_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE
    -- include months after Sept so late uninstalls are captured
    _TABLE_SUFFIX BETWEEN '20180801' AND '20181031'
    AND event_name = 'app_remove'
  GROUP BY user_pseudo_id
),
user_status AS (
  SELECT
    i.user_pseudo_id,
    CASE
      -- uninstalled within 7 days of install
      WHEN u.uninstall_ts IS NOT NULL
           AND TIMESTAMP_MICROS(u.uninstall_ts)
               <= TIMESTAMP_MICROS(i.install_ts) + INTERVAL 7 DAY
      THEN TRUE
      ELSE FALSE
    END AS uninstalled_within_7d
  FROM installs AS i
  LEFT JOIN uninstalls AS u
  USING (user_pseudo_id)
)
SELECT
  ROUND(
    100 * SAFE_DIVIDE(
            COUNTIF(NOT uninstalled_within_7d),   -- kept app ≥7 days or never uninstalled
            COUNT(*)                              -- all installs in Aug‑Sep
          ), 4) AS pct_users_no_early_uninstall
FROM user_status;