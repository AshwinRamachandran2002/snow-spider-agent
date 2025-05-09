SELECT
  CAST(users_with_crash_count.users_with_crash AS FLOAT64) / total_users.total_users * 100 AS Percentage_of_users_who_experienced_crash
FROM (
  SELECT COUNT(DISTINCT user_pseudo_id) AS total_users
  FROM (
    SELECT
      u.user_pseudo_id
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
    WHERE DATE_DIFF(ue.uninstall_date, u.first_open_date, DAY) BETWEEN 0 AND 7
  ) users_uninstalled_within_7_days
) total_users,
(
  SELECT COUNT(DISTINCT u.user_pseudo_id) AS users_with_crash
  FROM (
    SELECT
      u.user_pseudo_id,
      u.first_open_date,
      ue.uninstall_date
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
    WHERE DATE_DIFF(ue.uninstall_date, u.first_open_date, DAY) BETWEEN 0 AND 7
  ) u
  INNER JOIN `firebase-public-project.analytics_153293282.events_*` e
    ON u.user_pseudo_id = e.user_pseudo_id
  WHERE e.event_name = 'app_exception'
    AND PARSE_DATE('%Y%m%d', e.event_date) BETWEEN u.first_open_date AND u.uninstall_date
) users_with_crash_count