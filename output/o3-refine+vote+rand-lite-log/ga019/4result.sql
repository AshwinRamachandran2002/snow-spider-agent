/* 7‑day uninstall (app_remove) analysis for installs during Aug–Sep 2018 */
WITH cohort AS (                          -- users that installed in Aug or Sep 2018
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS install_ts    -- time of (first) install
  FROM
    `firebase-public-project.analytics_153293282.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
    AND event_name = 'first_open'
  GROUP BY
    user_pseudo_id
),
removes AS (                              -- first uninstall we have for every user
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS remove_ts
  FROM
    `firebase-public-project.analytics_153293282.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20180801' AND '20181031'   -- allow removals after Sep
    AND event_name = 'app_remove'
  GROUP BY
    user_pseudo_id
)
SELECT
  ROUND(
    100 * SUM(
      CASE
        WHEN r.remove_ts IS NULL                                  -- never uninstalled
          OR r.remove_ts > c.install_ts + 604800000000            -- uninstall after 7 days
        THEN 1
        ELSE 0
      END
    ) / COUNT(*),                                                -- total installs
    4
  ) AS pct_users_no_uninstall_within_7d
FROM cohort c
LEFT JOIN removes r USING (user_pseudo_id);