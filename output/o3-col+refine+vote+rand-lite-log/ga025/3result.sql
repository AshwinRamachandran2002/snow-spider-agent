WITH
-- 1) First-open events in September 2018
first_open AS (
  SELECT
    user_pseudo_id,
    DATE(TIMESTAMP_MICROS(user_first_touch_timestamp)) AS first_open_date
  FROM `firebase-public-project.analytics_153293282.events_201809*`
  WHERE event_name = 'first_open'
),

-- 2) Uninstall (app_remove) events in September 2018
uninstall AS (
  SELECT
    user_pseudo_id,
    DATE(TIMESTAMP_MICROS(event_timestamp)) AS uninstall_date
  FROM `firebase-public-project.analytics_153293282.events_201809*`
  WHERE event_name = 'app_remove'
),

-- 3) Crash (app_exception) events in September 2018
crash AS (
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_201809*`
  WHERE event_name = 'app_exception'
),

-- 4) Users who uninstalled within 7 days of first-open
early_uninstall AS (
  SELECT DISTINCT fo.user_pseudo_id
  FROM first_open  AS fo
  JOIN uninstall   AS un
    ON fo.user_pseudo_id = un.user_pseudo_id
  WHERE DATE_DIFF(un.uninstall_date, fo.first_open_date, DAY) BETWEEN 0 AND 7
)

-- 5) Final percentage of early-uninstallers that experienced a crash
SELECT
  SAFE_DIVIDE(COUNT(DISTINCT c.user_pseudo_id),               -- early-uninstallers WITH crash
              COUNT(DISTINCT eu.user_pseudo_id)) * 100
    AS pct_early_uninstallers_that_crashed
FROM early_uninstall AS eu
LEFT JOIN crash AS c
  ON eu.user_pseudo_id = c.user_pseudo_id;