SELECT
    "APP_GROUP_ID"                                AS app_group_id,
    TO_DATE('1970-01-01') + FLOOR("TIME" / 86400) AS session_start_day,
    COUNT(DISTINCT "USER_ID")                     AS unique_users_started_sessions
FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_BEHAVIORS_APP_SESSIONSTART_VIEW"
WHERE "TIME" BETWEEN 1685577600   -- 2023‑06‑01 00:00:00 UTC
                 AND 1686182399   -- 2023‑06‑07 23:59:59 UTC
GROUP BY
    "APP_GROUP_ID",
    TO_DATE('1970-01-01') + FLOOR("TIME" / 86400)
ORDER BY
    session_start_day,
    app_group_id;