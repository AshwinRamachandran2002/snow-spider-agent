WITH session_events AS (
    SELECT
        "APP_GROUP_ID",
        DATE_TRUNC(
            'DAY',
            COALESCE(
                TO_TIMESTAMP_LTZ("TIME"),      -- convert epoch seconds if present
                "SF_CREATED_AT"                -- fall-back to timestamp column
            )
        ) AS "SESSION_START_DAY",
        "USER_ID"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_BEHAVIORS_APP_SESSIONSTART_VIEW"
    WHERE
        COALESCE(TO_TIMESTAMP_LTZ("TIME"), "SF_CREATED_AT") >= '2023-06-01'::DATE
        AND COALESCE(TO_TIMESTAMP_LTZ("TIME"), "SF_CREATED_AT") <  '2023-06-08'::DATE
)

SELECT
    "APP_GROUP_ID",
    "SESSION_START_DAY",
    COUNT(DISTINCT "USER_ID") AS "UNIQUE_USER_COUNT"
FROM session_events
GROUP BY
    "APP_GROUP_ID",
    "SESSION_START_DAY"
ORDER BY
    "APP_GROUP_ID",
    "SESSION_START_DAY" NULLS LAST;