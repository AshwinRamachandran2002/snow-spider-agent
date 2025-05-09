WITH first_open_users AS (
    SELECT DISTINCT `user_pseudo_id`, DATE(TIMESTAMP_MICROS(`user_first_touch_timestamp`)) AS first_touch_date
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE EXTRACT(YEAR FROM DATE(TIMESTAMP_MICROS(`user_first_touch_timestamp`))) = 2018
      AND EXTRACT(MONTH FROM DATE(TIMESTAMP_MICROS(`user_first_touch_timestamp`))) = 9
),
uninstall_events AS (
    SELECT
        `user_pseudo_id`,
        DATE(TIMESTAMP_MICROS(`event_timestamp`)) AS uninstall_date
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE LOWER(`event_name`) = 'app_remove'
),
users_who_uninstalled_within_7_days AS (
    SELECT
        u.`user_pseudo_id`,
        u.first_touch_date,
        e.uninstall_date,
        DATE_DIFF(e.uninstall_date, u.first_touch_date, DAY) AS days_since_first_use
    FROM first_open_users u
    INNER JOIN uninstall_events e
    ON u.`user_pseudo_id` = e.`user_pseudo_id`
    WHERE DATE_DIFF(e.uninstall_date, u.first_touch_date, DAY) BETWEEN 0 AND 7
),
app_exception_events AS (
    SELECT DISTINCT `user_pseudo_id`
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE LOWER(`event_name`) = 'app_exception'
),
users_with_exception_before_uninstall AS (
    SELECT DISTINCT u.`user_pseudo_id`
    FROM users_who_uninstalled_within_7_days u
    INNER JOIN app_exception_events a
    ON u.`user_pseudo_id` = a.`user_pseudo_id`
)

SELECT
    ROUND(
        COUNT(DISTINCT uw.`user_pseudo_id`) * 100.0 / COUNT(DISTINCT u.`user_pseudo_id`),
        4
    ) AS Percentage
FROM users_who_uninstalled_within_7_days u
INNER JOIN users_with_exception_before_uninstall uw
ON u.`user_pseudo_id` = uw.`user_pseudo_id`