-- Percentage of September‑2018 new users who un‑installed within 7 days
-- and experienced at least one crash (app_exception)

WITH all_events AS (
  SELECT
    user_pseudo_id,
    event_name,
    event_timestamp,                 -- micro‑seconds
    user_first_touch_timestamp       -- micro‑seconds
  FROM `firebase-public-project.analytics_153293282.events_*`
  -- look at 1‑Sep‑2018 through 7‑Oct‑2018 (Sept plus 7‑day window)
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20181007'
),

/* 1. Users whose very first touch‑point is in September 2018 */
first_open_users AS (
  SELECT DISTINCT
    user_pseudo_id,
    DATE(TIMESTAMP_MICROS(user_first_touch_timestamp)) AS first_open_date
  FROM all_events
  WHERE DATE(TIMESTAMP_MICROS(user_first_touch_timestamp))
        BETWEEN '2018-09-01' AND '2018-09-30'
),

/* 2. Their uninstall (app_remove) date */
uninstalls AS (
  SELECT
    user_pseudo_id,
    MIN(DATE(TIMESTAMP_MICROS(event_timestamp))) AS uninstall_date
  FROM all_events
  WHERE event_name = 'app_remove'
  GROUP BY user_pseudo_id
),

/* 3. Users who triggered at least one crash (app_exception) */
crashes AS (
  SELECT DISTINCT user_pseudo_id
  FROM all_events
  WHERE event_name = 'app_exception'
),

/* 4. Combine & keep only 7‑day uninstallers */
target_users AS (
  SELECT
    fo.user_pseudo_id,
    fo.first_open_date,
    un.uninstall_date,
    IF(cr.user_pseudo_id IS NOT NULL, 1, 0) AS experienced_crash
  FROM first_open_users fo
  JOIN uninstalls     un ON fo.user_pseudo_id = un.user_pseudo_id
  LEFT JOIN crashes   cr ON fo.user_pseudo_id = cr.user_pseudo_id
  WHERE DATE_DIFF(un.uninstall_date, fo.first_open_date, DAY) BETWEEN 0 AND 7
)

SELECT
  ROUND( COUNTIF(experienced_crash = 1) * 100.0 / COUNT(*), 4 ) AS pct_uninstallers_with_crash
FROM target_users;