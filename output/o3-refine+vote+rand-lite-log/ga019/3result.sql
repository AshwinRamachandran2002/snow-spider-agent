-- % of users who installed in Aug‑Sep 2018 and did NOT uninstall within 7 days
WITH install_events AS (
  -- every event that belongs to a first‑time install during Aug & Sep 2018
  SELECT
    user_pseudo_id,
    user_first_touch_timestamp AS install_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
    AND user_first_touch_timestamp IS NOT NULL
),
first_installs AS (
  -- one install per user (the earliest during the period)
  SELECT
    user_pseudo_id,
    MIN(install_ts) AS install_ts
  FROM install_events
  GROUP BY user_pseudo_id
),
uninstall_events AS (
  -- first uninstall we have for each user (through 7‑Oct‑2018 to catch the 7‑day window)
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS uninstall_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20181007'      -- covers the 7‑day window for late‑Sep installs
    AND event_name = 'app_remove'                            -- Firebase uninstall event
  GROUP BY user_pseudo_id
),
analysis AS (
  SELECT
    i.user_pseudo_id,
    i.install_ts,
    u.uninstall_ts,
    -- TRUE if there is an uninstall ≤ 7 days after install
    CASE
      WHEN u.uninstall_ts IS NOT NULL
           AND u.uninstall_ts - i.install_ts <= 7*24*60*60*1000000
      THEN TRUE
      ELSE FALSE
    END AS uninstall_within_7d
  FROM first_installs i
  LEFT JOIN uninstall_events u
  USING (user_pseudo_id)
),
summary AS (
  SELECT
    COUNT(*)                                    AS total_users,
    COUNTIF(NOT uninstall_within_7d)            AS kept_or_late_users      -- the users we care about
  FROM analysis
)
SELECT
  ROUND(SAFE_DIVIDE(kept_or_late_users, total_users) * 100, 4)
    AS percent_of_users_without_7day_uninstall
FROM summary;