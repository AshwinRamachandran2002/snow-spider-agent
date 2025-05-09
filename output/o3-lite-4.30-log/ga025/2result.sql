WITH all_events AS (
  SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180901`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180902`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180903`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180904`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180905`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180906`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180907`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180908`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180909`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180910`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180911`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180912`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180913`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180914`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180915`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180916`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180917`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180918`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180919`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180920`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180921`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180922`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180923`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180924`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180925`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180926`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180927`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180928`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180929`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180930`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20181001`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20181002`
  UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20181003`
),
events AS (
  SELECT
    user_pseudo_id,
    event_name,
    PARSE_DATE('%Y%m%d', event_date) AS event_dt
  FROM all_events
),
first_open AS (
  SELECT
    user_pseudo_id,
    MIN(event_dt) AS first_open_dt
  FROM events
  WHERE event_name = 'first_open'
    AND event_dt BETWEEN DATE '2018-09-01' AND DATE '2018-09-30'
  GROUP BY user_pseudo_id
),
uninstall_7d AS (
  SELECT
    e.user_pseudo_id,
    MIN(e.event_dt) AS uninstall_dt
  FROM events e
  JOIN first_open f
    ON e.user_pseudo_id = f.user_pseudo_id
  WHERE e.event_name = 'app_remove'
    AND e.event_dt BETWEEN f.first_open_dt
                        AND DATE_ADD(f.first_open_dt, INTERVAL 7 DAY)
  GROUP BY e.user_pseudo_id
),
crashed_users AS (
  SELECT DISTINCT
         u.user_pseudo_id
  FROM   uninstall_7d u
  JOIN   events e
    ON   e.user_pseudo_id = u.user_pseudo_id
  WHERE  e.event_name = 'app_exception'
    AND  e.event_dt <= u.uninstall_dt
)
SELECT
  ROUND(
      100 * (SELECT COUNT(*) FROM crashed_users)
      / NULLIF((SELECT COUNT(*) FROM uninstall_7d), 0)
    , 4) AS crash_percentage_within_7d;