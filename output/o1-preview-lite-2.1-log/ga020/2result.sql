WITH initial_users AS (
    SELECT 
        event_name AS quickplay_event_type,
        user_pseudo_id,
        MIN(event_timestamp) AS first_engagement_timestamp
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180815'
      AND event_name LIKE '%quickplay%'
    GROUP BY quickplay_event_type, user_pseudo_id
),
user_events AS (
    SELECT 
        user_pseudo_id,
        event_timestamp
    FROM `firebase-public-project.analytics_153293282.events_*`
),
users_with_retention AS (
    SELECT 
        iu.quickplay_event_type,
        iu.user_pseudo_id,
        IF(
            EXISTS (
                SELECT 1
                FROM user_events ue
                WHERE ue.user_pseudo_id = iu.user_pseudo_id
                  AND ue.event_timestamp BETWEEN iu.first_engagement_timestamp + 7*24*3600*1000000
                                              AND iu.first_engagement_timestamp + 14*24*3600*1000000 - 1
            ), TRUE, FALSE
        ) AS retained_in_second_week
    FROM initial_users iu
),
retention_summary AS (
    SELECT 
        quickplay_event_type,
        COUNT(DISTINCT user_pseudo_id) AS total_users,
        COUNTIF(retained_in_second_week) AS retained_users
    FROM users_with_retention
    GROUP BY quickplay_event_type
),
retention_rate AS (
    SELECT 
        quickplay_event_type,
        ROUND(SAFE_DIVIDE(retained_users, total_users)*100, 4) AS retention_rate_second_week
    FROM retention_summary
)
SELECT quickplay_event_type, retention_rate_second_week
FROM retention_rate
ORDER BY retention_rate_second_week ASC
LIMIT 1