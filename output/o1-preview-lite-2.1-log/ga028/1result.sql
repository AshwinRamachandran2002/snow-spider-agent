WITH first_session AS (
    SELECT
        user_pseudo_id,
        MIN(DATE(TIMESTAMP_MICROS(event_timestamp))) AS first_session_date
    FROM (
        SELECT user_pseudo_id, event_timestamp
        FROM `firebase-public-project.analytics_153293282.events_20180702`
        WHERE event_name = 'session_start'
        UNION ALL
        SELECT user_pseudo_id, event_timestamp
        FROM `firebase-public-project.analytics_153293282.events_20180703`
        WHERE event_name = 'session_start'
        UNION ALL
        SELECT user_pseudo_id, event_timestamp
        FROM `firebase-public-project.analytics_153293282.events_20180704`
        WHERE event_name = 'session_start'
        UNION ALL
        SELECT user_pseudo_id, event_timestamp
        FROM `firebase-public-project.analytics_153293282.events_20180705`
        WHERE event_name = 'session_start'
        UNION ALL
        SELECT user_pseudo_id, event_timestamp
        FROM `firebase-public-project.analytics_153293282.events_20180706`
        WHERE event_name = 'session_start'
        UNION ALL
        SELECT user_pseudo_id, event_timestamp
        FROM `firebase-public-project.analytics_153293282.events_20180707`
        WHERE event_name = 'session_start'
        UNION ALL
        SELECT user_pseudo_id, event_timestamp
        FROM `firebase-public-project.analytics_153293282.events_20180708`
        WHERE event_name = 'session_start'
    )
    GROUP BY user_pseudo_id
),
new_users AS (
    SELECT user_pseudo_id
    FROM first_session
    WHERE first_session_date BETWEEN '2018-07-02' AND '2018-07-08'
),
week0 AS (
    SELECT 'Week0' AS Week, COUNT(DISTINCT user_pseudo_id) AS Number_of_Users
    FROM new_users
),
week1 AS (
    SELECT 'Week1' AS Week, COUNT(DISTINCT user_pseudo_id) AS Number_of_Users
    FROM (
        SELECT DISTINCT user_pseudo_id
        FROM (
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180709`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180710`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180711`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180712`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180713`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180714`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180715`
        )
        WHERE DATE(TIMESTAMP_MICROS(event_timestamp)) BETWEEN '2018-07-09' AND '2018-07-15'
          AND user_pseudo_id IN (SELECT user_pseudo_id FROM new_users)
    )
),
week2 AS (
    SELECT 'Week2' AS Week, COUNT(DISTINCT user_pseudo_id) AS Number_of_Users
    FROM (
        SELECT DISTINCT user_pseudo_id
        FROM (
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180716`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180717`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180718`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180719`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180720`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180721`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180722`
        )
        WHERE DATE(TIMESTAMP_MICROS(event_timestamp)) BETWEEN '2018-07-16' AND '2018-07-22'
          AND user_pseudo_id IN (SELECT user_pseudo_id FROM new_users)
    )
),
week3 AS (
    SELECT 'Week3' AS Week, COUNT(DISTINCT user_pseudo_id) AS Number_of_Users
    FROM (
        SELECT DISTINCT user_pseudo_id
        FROM (
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180723`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180724`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180725`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180726`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180727`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180728`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180729`
        )
        WHERE DATE(TIMESTAMP_MICROS(event_timestamp)) BETWEEN '2018-07-23' AND '2018-07-29'
          AND user_pseudo_id IN (SELECT user_pseudo_id FROM new_users)
    )
),
week4 AS (
    SELECT 'Week4' AS Week, COUNT(DISTINCT user_pseudo_id) AS Number_of_Users
    FROM (
        SELECT DISTINCT user_pseudo_id
        FROM (
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180730`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180731`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180801`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180802`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180803`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180804`
            UNION ALL
            SELECT user_pseudo_id, event_timestamp
            FROM `firebase-public-project.analytics_153293282.events_20180805`
        )
        WHERE DATE(TIMESTAMP_MICROS(event_timestamp)) BETWEEN '2018-07-30' AND '2018-08-05'
          AND user_pseudo_id IN (SELECT user_pseudo_id FROM new_users)
    )
)

SELECT * FROM week0
UNION ALL
SELECT * FROM week1
UNION ALL
SELECT * FROM week2
UNION ALL
SELECT * FROM week3
UNION ALL
SELECT * FROM week4
ORDER BY Week;