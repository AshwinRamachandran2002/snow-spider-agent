-- Task: Count the number of new users who had their first session start during the week starting on July 2, 2018.
WITH date_table AS (
    SELECT DISTINCT 
        PARSE_DATE('%Y%m%d', `event_date`) AS event_date,
        user_pseudo_id,
        CASE 
            WHEN DATE_DIFF(
                PARSE_DATE('%Y%m%d', `event_date`), 
                DATE(TIMESTAMP_MICROS(user_first_touch_timestamp)), 
                DAY
            ) = 0 THEN 1 ELSE 0 
        END AS is_new_user
    FROM 
        `firebase-public-project.analytics_153293282.events_*` 
    WHERE 
        event_name = 'session_start'
)
SELECT COUNT(DISTINCT user_pseudo_id) AS num_new_users
FROM date_table
WHERE is_new_user = 1 
    AND DATE_TRUNC(event_date, WEEK(MONDAY)) = DATE('2018-07-02')