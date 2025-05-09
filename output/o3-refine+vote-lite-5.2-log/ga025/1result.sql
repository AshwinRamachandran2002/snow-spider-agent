-- What % of September‑2018 first‑open users, who uninstalled within 7 days,
-- also had at least one app crash (event_name = 'app_exception') in that
-- same 7‑day window.
WITH base_events AS (
  SELECT
    user_pseudo_id,
    DATE(TIMESTAMP_MICROS(user_first_touch_timestamp))       AS first_open_date,
    event_name,
    DATE(TIMESTAMP_MICROS(event_timestamp))                  AS event_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  -- keep only the days we need: first‑opens in Sep‑2018 and the following week
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20181003'        -- yyyymmdd
),
/* 1. users whose very first open happened during September‑2018 */
first_open_users AS (
  SELECT DISTINCT
         user_pseudo_id,
         first_open_date
  FROM   base_events
  WHERE  first_open_date BETWEEN '2018-09-01' AND '2018-09-30'
),
/* 2. keep only those who un‑installed (app_remove) within 7 days */
uninstall_within_7 AS (
  SELECT
    fou.user_pseudo_id,
    fou.first_open_date,
    MIN(be.event_date) AS uninstall_date
  FROM first_open_users fou
  JOIN base_events    be
    ON  fou.user_pseudo_id = be.user_pseudo_id
   AND be.event_name      = 'app_remove'
  GROUP BY fou.user_pseudo_id, fou.first_open_date
  HAVING DATE_DIFF(MIN(be.event_date), fou.first_open_date, DAY) <= 7
),
/* 3. among the above, who had an app crash in the same 7‑day window? */
crash_users AS (
  SELECT DISTINCT uw.user_pseudo_id
  FROM   uninstall_within_7 uw
  JOIN   base_events       be
    ON  uw.user_pseudo_id = be.user_pseudo_id
   AND  be.event_name     = 'app_exception'
   AND  be.event_date BETWEEN uw.first_open_date
                          AND DATE_ADD(uw.first_open_date, INTERVAL 7 DAY)
)

SELECT
  COUNT(DISTINCT cu.user_pseudo_id)                                          AS users_with_crash,
  COUNT(DISTINCT uw.user_pseudo_id)                                          AS total_uninstalls_within_7,
  SAFE_DIVIDE(COUNT(DISTINCT cu.user_pseudo_id),
              COUNT(DISTINCT uw.user_pseudo_id)) * 100                       AS crash_percentage
FROM uninstall_within_7 uw
LEFT JOIN crash_users cu
       ON uw.user_pseudo_id = cu.user_pseudo_id;