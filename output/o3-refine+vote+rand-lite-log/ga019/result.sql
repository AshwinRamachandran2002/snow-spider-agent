/*  Percentage of users who installed in Aug‑Sep 2018 and
    did NOT uninstall within 7 days (including users that never uninstalled)
*/
WITH
-- 1. Users whose very first “first_open” happened in Aug/Sep‑2018
installs AS (
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS first_open_ts          -- micro‑seconds
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
    AND event_name = 'first_open'
  GROUP BY user_pseudo_id
),

-- 2. Earliest uninstall (“app_remove”) seen for those users (if any)
uninstalls AS (
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS remove_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20181003'   -- include later months to catch removals
    AND event_name = 'app_remove'
  GROUP BY user_pseudo_id
),

-- 3. Join installs with uninstalls and compute days until uninstall
joined AS (
  SELECT
    i.user_pseudo_id,
    i.first_open_ts,
    u.remove_ts,
    -- days difference (NULL when no uninstall)
    IF(u.remove_ts IS NULL,
       NULL,
       (u.remove_ts - i.first_open_ts) / 1e6 / 86400.0) AS days_to_remove
  FROM installs i
  LEFT JOIN uninstalls u
  USING (user_pseudo_id)
),

-- 4. Classify each user
classified AS (
  SELECT
    user_pseudo_id,
    CASE
      WHEN remove_ts IS NULL                     THEN 'never_removed'
      WHEN days_to_remove > 7                    THEN 'removed_after_7d'
      ELSE                                            'removed_within_7d'
    END AS removal_status
  FROM joined
)

-- 5. Final percentage
SELECT
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(removal_status IN ('never_removed','removed_after_7d')),
      COUNT(*)
    ) * 100,
    4
  ) AS pct_users_not_removed_within_7d
FROM classified;