SELECT
  ROUND(
    (COUNTIF(days_to_uninstall <= 7 AND has_crash = 1) * 100.0) /
    NULLIF(COUNTIF(days_to_uninstall <= 7), 0),
    4
  ) AS Percentage_of_users_who_experienced_crash
FROM (
  SELECT
    user_pseudo_id,
    first_touch_date,
    DATE_DIFF(MAX(event_date), first_touch_date, DAY) AS days_to_uninstall,
    MAX(IF(event_name = 'app_exception' AND event_date BETWEEN first_touch_date AND DATE_ADD(first_touch_date, INTERVAL 7 DAY), 1, 0)) AS has_crash
  FROM (
    SELECT 
      user_pseudo_id, 
      DATE(TIMESTAMP_MICROS(user_first_touch_timestamp)) AS first_touch_date,
      DATE(TIMESTAMP_MICROS(event_timestamp)) AS event_date,
      event_name
    FROM (
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180901`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180902`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180903`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180904`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180905`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180906`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180907`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180908`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180909`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180910`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180911`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180912`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180913`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180914`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180915`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180916`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180917`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180918`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180919`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180920`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180921`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180922`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180923`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180924`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180925`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180926`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180927`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180928`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180929`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20180930`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20181001`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20181002`
      UNION ALL
      SELECT user_pseudo_id, user_first_touch_timestamp, event_timestamp, event_name
      FROM `firebase-public-project.analytics_153293282.events_20181003`
    )
  )
  WHERE first_touch_date BETWEEN '2018-09-01' AND '2018-09-30'
  GROUP BY user_pseudo_id, first_touch_date
)