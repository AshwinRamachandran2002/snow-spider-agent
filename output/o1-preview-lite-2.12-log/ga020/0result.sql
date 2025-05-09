WITH
  initial_users AS (
    SELECT 
      user_pseudo_id,
      MIN(DATE(TIMESTAMP_MICROS(event_timestamp))) AS first_engagement_date
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE 
      _TABLE_SUFFIX BETWEEN '20180801' AND '20180815'
      AND event_name = 'session_start'
    GROUP BY user_pseudo_id
    HAVING first_engagement_date BETWEEN DATE '2018-08-01' AND DATE '2018-08-15'
  ),
  user_quickplay_events AS (
    SELECT DISTINCT
      t.user_pseudo_id,
      t.event_name AS quickplay_event_type
    FROM `firebase-public-project.analytics_153293282.events_*` AS t
    WHERE 
      _TABLE_SUFFIX BETWEEN '20180801' AND '20180815'
      AND t.user_pseudo_id IN (SELECT user_pseudo_id FROM initial_users)
      AND t.event_name LIKE '%_quickplay'
  ),
  user_second_week AS (
    SELECT
      iu.user_pseudo_id,
      iu.first_engagement_date,
      DATE_ADD(iu.first_engagement_date, INTERVAL 7 DAY) AS second_week_start_date,
      DATE_ADD(iu.first_engagement_date, INTERVAL 13 DAY) AS second_week_end_date
    FROM
      initial_users AS iu
  ),
  user_retention AS (
    SELECT
      usw.user_pseudo_id,
      CASE WHEN COUNT(t.event_name) > 0 THEN TRUE ELSE FALSE END AS retained
    FROM
      user_second_week AS usw
    LEFT JOIN
      `firebase-public-project.analytics_153293282.events_*` AS t
    ON
      t.user_pseudo_id = usw.user_pseudo_id
      AND t.event_name = 'session_start'
      AND DATE(TIMESTAMP_MICROS(t.event_timestamp)) BETWEEN usw.second_week_start_date AND usw.second_week_end_date
      AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', usw.second_week_start_date) AND FORMAT_DATE('%Y%m%d', usw.second_week_end_date)
    GROUP BY
      usw.user_pseudo_id
  ),
  user_quickplay_retention AS (
    SELECT
      uq.quickplay_event_type,
      ur.retained
    FROM
      user_quickplay_events AS uq
    JOIN
      user_retention AS ur
    ON
      uq.user_pseudo_id = ur.user_pseudo_id
  )

SELECT
  quickplay_event_type AS Quickplay_event_type,
  ROUND(100 * SUM(IF(retained, 1, 0)) / COUNT(*), 4) AS Retention_rate
FROM
  user_quickplay_retention
GROUP BY
  quickplay_event_type
ORDER BY
  Retention_rate ASC
LIMIT 1;