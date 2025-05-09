WITH session_events AS (
    SELECT
        DATE(
            COALESCE(
                IFF("TIME" IS NOT NULL, TO_TIMESTAMP_LTZ("TIME"), NULL),
                "SF_CREATED_AT"
            )
        )                                   AS start_day ,
        "APP_GROUP_ID" ,
        "USER_ID"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_BEHAVIORS_APP_SESSIONSTART_VIEW
    WHERE COALESCE(
              IFF("TIME" IS NOT NULL, TO_TIMESTAMP_LTZ("TIME"), NULL),
              "SF_CREATED_AT"
          ) BETWEEN '2023-06-01'::TIMESTAMP_LTZ
              AND '2023-06-07 23:59:59'::TIMESTAMP_LTZ
)

SELECT
    start_day                                           AS session_start_day ,
    "APP_GROUP_ID" ,
    COUNT(DISTINCT "USER_ID")                           AS unique_users_started_sessions
FROM session_events
GROUP BY
    start_day ,
    "APP_GROUP_ID"
ORDER BY
    start_day ,
    "APP_GROUP_ID";