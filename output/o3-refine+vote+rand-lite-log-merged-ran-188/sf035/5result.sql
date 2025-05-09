-- How many unique users started sessions each calendar day (per app-group)
-- between 1-Jun-2023 and 7-Jun-2023 (inclusive)?
SELECT
    DATE_TRUNC('day', TO_TIMESTAMP("TIME")) AS "session_day",
    "APP_GROUP_ID",
    COUNT(DISTINCT "USER_ID")               AS "unique_users"
FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_BEHAVIORS_APP_SESSIONSTART_VIEW"
WHERE "TIME" >= 1685577600                     -- 2023-06-01 00:00:00 UTC
  AND "TIME" <  1686182400                     -- 2023-06-08 00:00:00 UTC
GROUP BY
    "session_day",
    "APP_GROUP_ID"
ORDER BY
    "session_day",
    "APP_GROUP_ID";