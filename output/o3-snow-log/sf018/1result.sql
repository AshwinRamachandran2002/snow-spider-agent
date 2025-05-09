/* Examine user engagement with push-notifications between
   08:00 and 09:00 UTC on 01-Jun-2023 (Unix time 1 685 606 400-1 685 610 000) */

WITH union_events AS (

    /* Sends */
    SELECT
        "PLATFORM",
        "USER_ID",
        'send' AS "event_type"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_SEND_VIEW"
    WHERE "TIME" >= 1685606400
      AND "TIME" <  1685610000

    UNION ALL

    /* Bounces */
    SELECT
        "PLATFORM",
        "USER_ID",
        'bounce' AS "event_type"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_BOUNCE_VIEW"
    WHERE "TIME" >= 1685606400
      AND "TIME" <  1685610000

    UNION ALL

    /* Opens */
    SELECT
        "PLATFORM",
        "USER_ID",
        'open' AS "event_type"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_OPEN_VIEW"
    WHERE "TIME" >= 1685606400
      AND "TIME" <  1685610000

    UNION ALL

    /* Influenced Opens */
    SELECT
        "PLATFORM",
        "USER_ID",
        'influenced_open' AS "event_type"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_INFLUENCEDOPEN_VIEW"
    WHERE "TIME" >= 1685606400
      AND "TIME" <  1685610000
)

SELECT
    "PLATFORM",

    /* Sends */
    SUM( CASE WHEN "event_type" = 'send'            THEN 1 ELSE 0 END )                                   AS "push_notification_sends",
    COUNT( DISTINCT CASE WHEN "event_type" = 'send' THEN "USER_ID" END )                                   AS "unique_push_notification_sends",

    /* Bounces */
    SUM( CASE WHEN "event_type" = 'bounce'          THEN 1 ELSE 0 END )                                   AS "push_notification_bounced",
    COUNT( DISTINCT CASE WHEN "event_type" = 'bounce' THEN "USER_ID" END )                                 AS "unique_push_notification_bounced",

    /* Opens */
    SUM( CASE WHEN "event_type" = 'open'            THEN 1 ELSE 0 END )                                   AS "push_notification_open",
    COUNT( DISTINCT CASE WHEN "event_type" = 'open' THEN "USER_ID" END )                                   AS "unique_push_notification_opened",

    /* Influenced Opens */
    SUM( CASE WHEN "event_type" = 'influenced_open' THEN 1 ELSE 0 END )                                   AS "push_notification_influenced_open",
    COUNT( DISTINCT CASE WHEN "event_type" = 'influenced_open' THEN "USER_ID" END )                        AS "unique_push_notification_influenced_open"

FROM union_events
GROUP BY "PLATFORM"
ORDER BY "PLATFORM" NULLS LAST;