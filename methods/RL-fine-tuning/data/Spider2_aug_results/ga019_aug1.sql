-- Task: For each user who installed our app during August and September 2018, find the date they first opened the app, the date they uninstalled it (if any), and the number of days until they uninstalled. Limit the result to 100 rows.

WITH
  sept_cohort AS (
    SELECT DISTINCT user_pseudo_id,
      FORMAT_DATE('%Y-%m-%d', PARSE_DATE('%Y%m%d', event_date)) AS date_first_open
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE event_name = 'first_open'
      AND _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
  ),
  uninstallers AS (
    SELECT DISTINCT user_pseudo_id,
      FORMAT_DATE('%Y-%m-%d', PARSE_DATE('%Y%m%d', event_date)) AS date_app_remove
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE event_name = 'app_remove'
      AND _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
  )
SELECT
  a.user_pseudo_id,
  a.date_first_open,
  b.date_app_remove,
  DATE_DIFF(DATE(b.date_app_remove), DATE(a.date_first_open), DAY) AS days_to_uninstall
FROM sept_cohort a
LEFT JOIN uninstallers b
  ON a.user_pseudo_id = b.user_pseudo_id
LIMIT 100