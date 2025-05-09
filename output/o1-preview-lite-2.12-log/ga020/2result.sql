WITH initial_users AS (
  SELECT DISTINCT
    e.user_pseudo_id,
    e.user_first_touch_timestamp,
    e.event_name AS quickplay_event_type
  FROM
    `firebase-public-project.analytics_153293282.events_*` e
  WHERE
    e.event_name LIKE '%quickplay%'
    AND DATE(TIMESTAMP_MICROS(e.user_first_touch_timestamp)) BETWEEN '2018-08-01' AND '2018-08-15'
),
retained_users AS (
  SELECT DISTINCT
    iu.user_pseudo_id,
    iu.quickplay_event_type
  FROM
    initial_users iu
  JOIN
    `firebase-public-project.analytics_153293282.events_*` e
  ON
    iu.user_pseudo_id = e.user_pseudo_id
  WHERE
    e.event_name = 'session_start'
    AND TIMESTAMP_MICROS(e.event_timestamp) BETWEEN TIMESTAMP_MICROS(iu.user_first_touch_timestamp) + INTERVAL 7 DAY
                                                 AND TIMESTAMP_MICROS(iu.user_first_touch_timestamp) + INTERVAL 14 DAY
)
SELECT
  iu.quickplay_event_type AS Quickplay_event_type,
  ROUND((COUNT(DISTINCT ru.user_pseudo_id) / COUNT(DISTINCT iu.user_pseudo_id)) * 100, 4) AS Retention_rate
FROM
  initial_users iu
LEFT JOIN
  retained_users ru
ON
  iu.user_pseudo_id = ru.user_pseudo_id
  AND iu.quickplay_event_type = ru.quickplay_event_type
GROUP BY
  Quickplay_event_type
ORDER BY
  Retention_rate ASC
LIMIT 1