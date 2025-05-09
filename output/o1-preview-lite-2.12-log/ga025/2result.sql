SELECT
  ROUND((
    (SELECT COUNT(DISTINCT e1.user_pseudo_id)
     FROM `firebase-public-project`.`analytics_153293282`.`events_201809*` AS e1
     JOIN `firebase-public-project`.`analytics_153293282`.`events_201809*` AS e2
       ON e1.user_pseudo_id = e2.user_pseudo_id
     WHERE e1.event_name = 'app_remove'
       AND e2.event_name = 'app_exception'
       AND DATE(TIMESTAMP_MICROS(e1.user_first_touch_timestamp)) BETWEEN '2018-09-01' AND '2018-09-30'
       AND DATE_DIFF(
         DATE(TIMESTAMP_MICROS(e1.event_timestamp)),
         DATE(TIMESTAMP_MICROS(e1.user_first_touch_timestamp)),
         DAY
       ) <= 7
       AND DATE(TIMESTAMP_MICROS(e2.event_timestamp)) < DATE(TIMESTAMP_MICROS(e1.event_timestamp))
    ) /
    (SELECT COUNT(DISTINCT user_pseudo_id)
     FROM `firebase-public-project`.`analytics_153293282`.`events_201809*`
     WHERE event_name = 'app_remove'
       AND DATE(TIMESTAMP_MICROS(user_first_touch_timestamp)) BETWEEN '2018-09-01' AND '2018-09-30'
       AND DATE_DIFF(
         DATE(TIMESTAMP_MICROS(event_timestamp)),
         DATE(TIMESTAMP_MICROS(user_first_touch_timestamp)),
         DAY
       ) <= 7
    ) * 100
  ), 4) AS Percentage