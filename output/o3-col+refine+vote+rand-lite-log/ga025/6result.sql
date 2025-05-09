-- Percentage of September-2018 new users who uninstalled ≤7 days after
-- first_open and, within that cohort, the share that recorded at least
-- one crash (app_exception).

WITH first_open AS (   -- first_open date per user
  SELECT
    user_pseudo_id,
    MIN(DATE(TIMESTAMP_MICROS(event_timestamp))) AS first_open_date
  FROM `firebase-public-project.analytics_153293282.events_201809*`
  WHERE event_name = 'first_open'
  GROUP BY user_pseudo_id
),

uninstall AS (         -- earliest uninstall (app_remove) date per user
  SELECT
    user_pseudo_id,
    MIN(DATE(TIMESTAMP_MICROS(event_timestamp))) AS uninstall_date
  FROM `firebase-public-project.analytics_153293282.events_201809*`
  WHERE event_name = 'app_remove'
  GROUP BY user_pseudo_id
),

crashes AS (           -- any user that generated at least one crash
  SELECT DISTINCT
    user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_201809*`
  WHERE event_name = 'app_exception'
),

base AS (              -- join the three sets and keep ≤7-day uninstalls
  SELECT
    fo.user_pseudo_id,
    fo.first_open_date,
    u.uninstall_date,
    DATE_DIFF(u.uninstall_date, fo.first_open_date, DAY) AS days_to_uninstall,
    IF(c.user_pseudo_id IS NULL, 0, 1) AS had_crash
  FROM first_open  fo
  JOIN uninstall   u USING (user_pseudo_id)
  LEFT JOIN crashes c USING (user_pseudo_id)
  WHERE DATE_DIFF(u.uninstall_date, fo.first_open_date, DAY) BETWEEN 0 AND 7
)

SELECT
  ROUND(
    100 * SAFE_DIVIDE(COUNTIF(had_crash = 1), COUNT(*)),
    2
  ) AS pct_with_crash
FROM base;