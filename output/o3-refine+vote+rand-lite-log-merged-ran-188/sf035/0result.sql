SELECT
       "APP_GROUP_ID",
       DATE(TO_TIMESTAMP_LTZ("TIME"))                       AS "session_start_day",
       COUNT(DISTINCT "USER_ID")                            AS "unique_users_started_sessions"
FROM   "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_BEHAVIORS_APP_SESSIONSTART_VIEW"
WHERE  DATE(TO_TIMESTAMP_LTZ("TIME")) BETWEEN '2023-06-01' AND '2023-06-07'
GROUP BY
       "APP_GROUP_ID",
       DATE(TO_TIMESTAMP_LTZ("TIME"))
ORDER BY
       "session_start_day",
       "APP_GROUP_ID";