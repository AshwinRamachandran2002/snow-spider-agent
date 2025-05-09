/* Examine user engagement with push-notifications that occurred
   between 08:00 UTC and 09:00 UTC on 01-Jun-2023. 
    
   For every campaign / platform pair the query returns:
     – total & unique SENDS
     – total & unique BOUNCES
     – total & unique OPENS
     – total & unique INFLUENCED-OPENS
     – a simple open-rate  (opens ÷ sends)                             */

WITH all_events AS (

    /* 1. SEND events */
    SELECT
        "CAMPAIGN_ID",
        "PLATFORM",
        "USER_ID",
        'send'            AS "event_type"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_SEND_VIEW"
    WHERE "TIME" BETWEEN 1685606400 AND 1685610000          -- 08:00-09:00 01-Jun-2023

    UNION ALL

    /* 2. BOUNCE events */
    SELECT
        "CAMPAIGN_ID",
        "PLATFORM",
        "USER_ID",
        'bounce'
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_BOUNCE_VIEW"
    WHERE "TIME" BETWEEN 1685606400 AND 1685610000

    UNION ALL

    /* 3. OPEN events */
    SELECT
        "CAMPAIGN_ID",
        "PLATFORM",
        "USER_ID",
        'open'
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_OPEN_VIEW"
    WHERE "TIME" BETWEEN 1685606400 AND 1685610000

    UNION ALL

    /* 4. INFLUENCED-OPEN events */
    SELECT
        "CAMPAIGN_ID",
        "PLATFORM",
        "USER_ID",
        'influenced_open'
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_INFLUENCEDOPEN_VIEW"
    WHERE "TIME" BETWEEN 1685606400 AND 1685610000
)

SELECT
    "CAMPAIGN_ID",
    "PLATFORM",

    /* SENDS */
    COUNT_IF("event_type" = 'send')                                                         AS "push_notification_sends",
    COUNT(DISTINCT CASE WHEN "event_type" = 'send' THEN "USER_ID" END)                     AS "unique_push_notification_sends",

    /* BOUNCES */
    COUNT_IF("event_type" = 'bounce')                                                       AS "push_notification_bounces",
    COUNT(DISTINCT CASE WHEN "event_type" = 'bounce' THEN "USER_ID" END)                   AS "unique_push_notification_bounces",

    /* OPENS */
    COUNT_IF("event_type" = 'open')                                                         AS "push_notification_opens",
    COUNT(DISTINCT CASE WHEN "event_type" = 'open' THEN "USER_ID" END)                     AS "unique_push_notification_opens",

    /* INFLUENCED-OPENS */
    COUNT_IF("event_type" = 'influenced_open')                                              AS "push_notification_influenced_opens",
    COUNT(DISTINCT CASE WHEN "event_type" = 'influenced_open' THEN "USER_ID" END)          AS "unique_push_notification_influenced_opens",

    /* SIMPLE OPEN-RATE */
    CASE 
        WHEN COUNT_IF("event_type" = 'send') = 0 THEN 0
        ELSE ROUND(
               COUNT_IF("event_type" = 'open')::FLOAT 
               / COUNT_IF("event_type" = 'send'),
               4
             )
    END                                                                                     AS "open_rate"

FROM all_events
GROUP BY
    "CAMPAIGN_ID",
    "PLATFORM"
ORDER BY
    "open_rate"                 DESC NULLS LAST,
    "push_notification_sends"   DESC NULLS LAST;