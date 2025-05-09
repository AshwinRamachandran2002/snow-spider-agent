-- Daily count of distinct users who started a session (June 1 – 7 2023)   
SELECT
    "APP_GROUP_ID",
    /* Convert epoch seconds to a date (UTC) */
    DATE_FROM_PARTS(1970, 1, 1) + ("TIME" / 86400)::INTEGER  AS "start_day",
    COUNT(DISTINCT "USER_ID")                                AS "unique_users_started_sessions"
FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_BEHAVIORS_APP_SESSIONSTART_VIEW"
WHERE "TIME" BETWEEN 1685577600   /* 2023-06-01 00:00:00 UTC */
                 AND 1686182399   /* 2023-06-07 23:59:59 UTC */
GROUP BY
    "APP_GROUP_ID",
    DATE_FROM_PARTS(1970, 1, 1) + ("TIME" / 86400)::INTEGER
ORDER BY
    "APP_GROUP_ID",
    "start_day";