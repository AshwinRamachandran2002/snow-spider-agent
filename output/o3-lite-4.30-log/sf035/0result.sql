SELECT
    "APP_GROUP_ID"                                   AS app_group_id,
    DATE_TRUNC('DAY', TO_TIMESTAMP("TIME"))          AS session_start_day,
    COUNT(DISTINCT "USER_ID")                        AS unique_users_started_sessions
FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_BEHAVIORS_APP_SESSIONSTART_VIEW"
WHERE TO_TIMESTAMP("TIME") >= '2023-06-01'
  AND TO_TIMESTAMP("TIME") <  '2023-06-08'
GROUP BY
    "APP_GROUP_ID",
    DATE_TRUNC('DAY', TO_TIMESTAMP("TIME"))
ORDER BY
    session_start_day,
    app_group_id;