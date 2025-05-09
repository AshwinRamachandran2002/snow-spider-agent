WITH initial_events AS (
    SELECT
        user_pseudo_id,
        MIN(event_timestamp) AS first_event_timestamp,
        event_name AS quickplay_event_type
    FROM
        `firebase-public-project.analytics_153293282.events_*`
    WHERE
        event_date BETWEEN '20180702' AND '20180716'
        AND event_name IN (
            'level_complete_quickplay',
            'level_end_quickplay',
            'level_fail_quickplay',
            'level_reset_quickplay',
            'level_retry_quickplay',
            'level_start_quickplay'
        )
    GROUP BY
        user_pseudo_id,
        event_name
),
session_users AS (
    SELECT DISTINCT user_pseudo_id
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE event_name = 'session_start'
      AND event_date BETWEEN '20180702' AND '20180716'
),
retention AS (
    SELECT
        ie.quickplay_event_type,
        ie.user_pseudo_id,
        ie.first_event_timestamp,
        TIMESTAMP_ADD(TIMESTAMP_MICROS(ie.first_event_timestamp), INTERVAL 14 DAY) AS start_retention_period,
        TIMESTAMP_ADD(TIMESTAMP_MICROS(ie.first_event_timestamp), INTERVAL 28 DAY) AS end_retention_period
    FROM
        initial_events ie
    JOIN
        session_users su
        ON ie.user_pseudo_id = su.user_pseudo_id
),
retained_users AS (
    SELECT DISTINCT
        r.quickplay_event_type,
        r.user_pseudo_id
    FROM
        retention r
    JOIN
        `firebase-public-project.analytics_153293282.events_*` ev
    ON
        r.user_pseudo_id = ev.user_pseudo_id
    WHERE
        ev.event_timestamp BETWEEN
            UNIX_MICROS(r.start_retention_period)
            AND UNIX_MICROS(r.end_retention_period)
        AND ev.event_name = r.quickplay_event_type
),
user_counts AS (
    SELECT
        quickplay_event_type,
        COUNT(DISTINCT user_pseudo_id) AS total_users
    FROM
        retention
    GROUP BY
        quickplay_event_type
),
retained_counts AS (
    SELECT
        quickplay_event_type,
        COUNT(DISTINCT user_pseudo_id) AS retained_users
    FROM
        retained_users
    GROUP BY
        quickplay_event_type
)
SELECT
    uc.quickplay_event_type,
    ROUND(100 * IFNULL(rc.retained_users, 0) / uc.total_users, 4) AS retention_rate_after_two_weeks
FROM
    user_counts uc
LEFT JOIN
    retained_counts rc
    ON uc.quickplay_event_type = rc.quickplay_event_type
ORDER BY
    uc.quickplay_event_type;