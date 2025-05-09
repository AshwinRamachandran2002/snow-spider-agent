WITH
    win AS (
        SELECT
            TO_TIMESTAMP_LTZ(1685606400) AS window_start,
            TO_TIMESTAMP_LTZ(1685610000) AS window_end
    ),
    sends AS (
        SELECT COUNT(*) AS total_notifications_sent
        FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_SEND_VIEW"
        WHERE "TIME" BETWEEN 1685606400 AND 1685610000
    ),
    opens AS (
        SELECT COUNT(*) AS total_notifications_opened
        FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_OPEN_VIEW"
        WHERE "TIME" BETWEEN 1685606400 AND 1685610000
    )
SELECT
    win.window_start,
    win.window_end,
    sends.total_notifications_sent,
    opens.total_notifications_opened,
    ROUND(opens.total_notifications_opened / NULLIF(sends.total_notifications_sent, 0), 4) AS open_rate
FROM win
CROSS JOIN sends
CROSS JOIN opens;