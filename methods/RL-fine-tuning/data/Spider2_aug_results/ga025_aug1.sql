-- Task: List up to 100 users who first opened the app in September 2018 and uninstalled, along with the number of days between their first open and uninstall date.

SELECT
  u.user_pseudo_id,
  u.first_open_date,
  ue.uninstall_date,
  DATE_DIFF(ue.uninstall_date, u.first_open_date, DAY) AS days_to_uninstall
FROM (
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_open_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'first_open'
    AND PARSE_DATE('%Y%m%d', event_date) BETWEEN DATE('2018-09-01') AND DATE('2018-09-30')
  GROUP BY user_pseudo_id
) u
INNER JOIN (
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS uninstall_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'app_remove'
  GROUP BY user_pseudo_id
) ue ON u.user_pseudo_id = ue.user_pseudo_id
LIMIT 100;