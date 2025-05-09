WITH first_sessions AS (
    SELECT 
        user_pseudo_id,
        MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_session_date
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE event_name = 'session_start'
      AND PARSE_DATE('%Y%m%d', event_date) >= DATE('2018-07-09')
      AND _TABLE_SUFFIX BETWEEN '20180709' AND '20181002'
    GROUP BY user_pseudo_id
),

user_cohorts AS (
    SELECT 
        user_pseudo_id,
        first_session_date,
        DATE_TRUNC(first_session_date, WEEK(MONDAY)) AS cohort_week_start_date,
        DATE_ADD(DATE_TRUNC(first_session_date, WEEK(MONDAY)), INTERVAL 7 DAY) AS week2_start_date,
        DATE_ADD(DATE_TRUNC(first_session_date, WEEK(MONDAY)), INTERVAL 13 DAY) AS week2_end_date
    FROM first_sessions
),

user_retention AS (
    SELECT 
        uc.user_pseudo_id,
        uc.cohort_week_start_date,
        IF(
            EXISTS (
                SELECT 1
                FROM `firebase-public-project.analytics_153293282.events_*` ev
                WHERE ev.user_pseudo_id = uc.user_pseudo_id
                  AND ev.event_name = 'session_start'
                  AND PARSE_DATE('%Y%m%d', ev.event_date) BETWEEN uc.week2_start_date AND uc.week2_end_date
                  AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', uc.week2_start_date) AND FORMAT_DATE('%Y%m%d', uc.week2_end_date)
            ), 1, 0) AS is_retained_in_week2
    FROM user_cohorts uc
),

cohort_retention AS (
    SELECT 
        cohort_week_start_date AS Cohort_Week_Start_Date,
        COUNT(*) AS cohort_size,
        SUM(is_retained_in_week2) AS retained_users
    FROM user_retention
    GROUP BY Cohort_Week_Start_Date
    ORDER BY Cohort_Week_Start_Date
    LIMIT 11
)

SELECT 
    Cohort_Week_Start_Date,
    ROUND(100 * SAFE_DIVIDE(retained_users, cohort_size), 4) AS Retention_Rate_Percentage
FROM cohort_retention;