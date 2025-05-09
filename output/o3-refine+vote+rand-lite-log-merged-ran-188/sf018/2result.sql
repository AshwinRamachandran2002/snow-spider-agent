WITH
    /* 1. Push-notification SEND events between 08:00–09:00 UTC on 2023-06-01 */
    send_events AS (
        SELECT
            "CAMPAIGN_ID",
            COUNT(*)                  AS "push_notification_sends",
            COUNT(DISTINCT "USER_ID") AS "unique_push_notification_sends"
        FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_SEND_VIEW"
        WHERE "TIME" >= 1685606400
          AND "TIME" < 1685610000
        GROUP BY "CAMPAIGN_ID"
    ),

    /* 2. Push-notification BOUNCE events in the same window */
    bounce_events AS (
        SELECT
            "CAMPAIGN_ID",
            COUNT(*)                  AS "push_notification_bounced",
            COUNT(DISTINCT "USER_ID") AS "unique_push_notification_bounced"
        FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_BOUNCE_VIEW"
        WHERE "TIME" >= 1685606400
          AND "TIME" < 1685610000
        GROUP BY "CAMPAIGN_ID"
    ),

    /* 3. Push-notification OPEN events in the same window */
    open_events AS (
        SELECT
            "CAMPAIGN_ID",
            COUNT(*)                  AS "push_notification_opened",
            COUNT(DISTINCT "USER_ID") AS "unique_push_notification_opened"
        FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_OPEN_VIEW"
        WHERE "TIME" >= 1685606400
          AND "TIME" < 1685610000
        GROUP BY "CAMPAIGN_ID"
    ),

    /* 4. Push-notification INFLUENCED OPEN events in the same window */
    influenced_open_events AS (
        SELECT
            "CAMPAIGN_ID",
            COUNT(*)                  AS "push_notification_influenced_open",
            COUNT(DISTINCT "USER_ID") AS "unique_push_notification_influenced_open"
        FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_INFLUENCEDOPEN_VIEW"
        WHERE "TIME" >= 1685606400
          AND "TIME" < 1685610000
        GROUP BY "CAMPAIGN_ID"
    )

/* 5. Combine all metrics per CAMPAIGN */
SELECT
    COALESCE(s."CAMPAIGN_ID",
             b."CAMPAIGN_ID",
             o."CAMPAIGN_ID",
             i."CAMPAIGN_ID")                                 AS "CAMPAIGN_ID",

    s."push_notification_sends",
    s."unique_push_notification_sends",

    b."push_notification_bounced",
    b."unique_push_notification_bounced",

    o."push_notification_opened",
    o."unique_push_notification_opened",

    i."push_notification_influenced_open",
    i."unique_push_notification_influenced_open"
FROM send_events             s
FULL OUTER JOIN bounce_events          b ON s."CAMPAIGN_ID" = b."CAMPAIGN_ID"
FULL OUTER JOIN open_events            o ON COALESCE(s."CAMPAIGN_ID", b."CAMPAIGN_ID") = o."CAMPAIGN_ID"
FULL OUTER JOIN influenced_open_events i ON COALESCE(s."CAMPAIGN_ID", b."CAMPAIGN_ID", o."CAMPAIGN_ID") = i."CAMPAIGN_ID"
ORDER BY "CAMPAIGN_ID" NULLS LAST;