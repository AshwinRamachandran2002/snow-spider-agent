/*  Percentage of September‑2018 first‑time users who un‑installed
    within 7 days and, in that period, experienced an app crash      */

WITH relevant_events AS (
  SELECT
    user_pseudo_id,
    DATE(TIMESTAMP_MICROS(user_first_touch_timestamp))      AS first_open_date,
    event_name,
    DATE(TIMESTAMP_MICROS(event_timestamp))                AS event_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  --  Include every daily table needed: first‑opens in Sep‑18
  --  and their seven‑day window that can extend to early Oct‑18
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20181007'
        AND user_first_touch_timestamp IS NOT NULL
),

/*  Users whose very first open happened in Sep‑2018                 */
first_open_users AS (
  SELECT DISTINCT user_pseudo_id, first_open_date
  FROM   relevant_events
  WHERE  first_open_date BETWEEN '2018-09-01' AND '2018-09-30'
),

/*  First uninstall (if any) for those users                         */
uninstall AS (
  SELECT
    user_pseudo_id,
    MIN(event_date) AS uninstall_date
  FROM   relevant_events
  WHERE  event_name = 'app_remove'
  GROUP  BY user_pseudo_id
),

/*  Users that registered at least one crash on/before uninstall     */
crash AS (
  SELECT DISTINCT e.user_pseudo_id
  FROM   relevant_events e
  JOIN   uninstall          u  USING (user_pseudo_id)
  WHERE  e.event_name = 'app_exception'
         AND e.event_date <= u.uninstall_date
),

/*  Target cohort: uninstalled within 7 days of first open           */
target_users AS (
  SELECT
    f.user_pseudo_id,
    f.first_open_date,
    u.uninstall_date,
    DATE_DIFF(u.uninstall_date, f.first_open_date, DAY) AS days_to_uninstall,
    c.user_pseudo_id IS NOT NULL                      AS had_crash
  FROM first_open_users f
  JOIN uninstall      u USING (user_pseudo_id)
  LEFT JOIN crash     c USING (user_pseudo_id)
  WHERE DATE_DIFF(u.uninstall_date, f.first_open_date, DAY) BETWEEN 0 AND 7
)

/*  Final percentage                                                 */
SELECT
  ROUND(100 * COUNTIF(had_crash) / COUNT(*), 4) AS pct_uninstalled_users_with_crash
FROM target_users;