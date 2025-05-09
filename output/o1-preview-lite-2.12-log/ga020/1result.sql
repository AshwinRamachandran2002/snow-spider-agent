WITH user_cohort AS (
    SELECT
        user_pseudo_id,
        user_first_touch_timestamp
    FROM
        `firebase-public-project.analytics_153293282.events_*`
    WHERE
        user_first_touch_timestamp BETWEEN UNIX_MICROS(TIMESTAMP('2018-08-01')) AND UNIX_MICROS(TIMESTAMP('2018-08-15 23:59:59'))
        AND event_date BETWEEN '20180801' AND '20180829'
    GROUP BY
        user_pseudo_id,
        user_first_touch_timestamp
),
first_week_quickplay_events AS (
    SELECT DISTINCT
        uc.user_pseudo_id,
        e.event_name AS Quickplay_event_type
    FROM
        user_cohort uc
    JOIN
        `firebase-public-project.analytics_153293282.events_*` e
    ON
        uc.user_pseudo_id = e.user_pseudo_id
    WHERE
        e.event_name LIKE '%_quickplay'
        AND e.event_timestamp BETWEEN uc.user_first_touch_timestamp AND uc.user_first_touch_timestamp + 7 * 86400000000
        AND e.event_date BETWEEN '20180801' AND '20180822'
),
second_week_session_start AS (
    SELECT DISTINCT
        uc.user_pseudo_id
    FROM
        user_cohort uc
    JOIN
        `firebase-public-project.analytics_153293282.events_*` e
    ON
        uc.user_pseudo_id = e.user_pseudo_id
    WHERE
        e.event_name = 'session_start'
        AND e.event_timestamp BETWEEN uc.user_first_touch_timestamp + 7 * 86400000000 AND uc.user_first_touch_timestamp + 14 * 86400000000
        AND e.event_date BETWEEN '20180808' AND '20180829'
)
SELECT
    fq.Quickplay_event_type,
    SAFE_DIVIDE(COUNT(DISTINCT CASE WHEN ss.user_pseudo_id IS NOT NULL THEN fq.user_pseudo_id END), COUNT(DISTINCT fq.user_pseudo_id)) * 100 AS Retention_rate
FROM
    first_week_quickplay_events fq
LEFT JOIN
    second_week_session_start ss
ON
    fq.user_pseudo_id = ss.user_pseudo_id
GROUP BY
    fq.Quickplay_event_type
ORDER BY
    Retention_rate ASC
LIMIT 1