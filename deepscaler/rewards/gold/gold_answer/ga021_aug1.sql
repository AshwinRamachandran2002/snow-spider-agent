-- Task: List the earliest date of quickplay event for each user within the period from July 2, 2018, to July 16, 2018.
SELECT 
    user_pseudo_id,
    event_name,
    MIN(PARSE_DATE('%Y%m%d', `event_date`)) AS event_cohort_date
FROM 
    `firebase-public-project.analytics_153293282.events_*` 
WHERE 
    event_name IN ('level_start_quickplay', 'level_end_quickplay', 'level_complete_quickplay', 
                   'level_fail_quickplay', 'level_reset_quickplay', 'level_retry_quickplay')
    AND PARSE_DATE('%Y%m%d', `event_date`) BETWEEN DATE('2018-07-02') AND DATE('2018-07-16')
GROUP BY 
    user_pseudo_id, event_name