WITH all_events AS (
  SELECT user_pseudo_id, event_name, event_date
  FROM `firebase-public-project.analytics_153293282.events_20180901`
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
    MIN(event_dt) AS fo_date
  FROM events
  WHERE event_name = 'first_open'
    AND event_dt BETWEEN DATE '2018-09-01' AND DATE '2018-09-30'
  GROUP BY user_pseudo_id
),
uninstall AS (
  SELECT
    user_pseudo_id,
    MIN(event_dt) AS uninstall_date
  FROM events
  WHERE event_name = 'app_remove'
  GROUP BY user_pseudo_id
),
cohort AS (
  SELECT
    f.user_pseudo_id,
    f.fo_date,
    u.uninstall_date
  FROM first_open f
  JOIN uninstall u USING (user_pseudo_id)
  WHERE DATE_DIFF(u.uninstall_date, f.fo_date, DAY) BETWEEN 0 AND 7
),
crashes AS (
  SELECT DISTINCT
    user_pseudo_id,
    event_dt AS crash_date
  FROM events
  WHERE event_name = 'app_exception'
)
SELECT
  ROUND(
    100 * COUNT(DISTINCT c.user_pseudo_id) / COUNT(DISTINCT cohort.user_pseudo_id)
  , 4) AS crash_percentage_within_7d
FROM cohort
LEFT JOIN crashes c
  ON c.user_pseudo_id = cohort.user_pseudo_id
 AND c.crash_date BETWEEN cohort.fo_date AND cohort.uninstall_date;