/* ---------------------------------------------------------------------------
   Examine push-notification engagement between 08:00 – 09:00 UTC on 01-Jun-2023
   – Counts & unique-user counts for each campaign / message-variation / platform
--------------------------------------------------------------------------- */
WITH all_events AS (
    /* 1)  Sends ------------------------------------------------------------ */
    SELECT
        'send'                        AS event_type,
        "CAMPAIGN_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "USER_ID"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_SEND_VIEW"
    WHERE "TIME" >= 1685606400  -- 2023-06-01 08:00:00 UTC
      AND "TIME" <  1685610000  -- 2023-06-01 09:00:00 UTC

    UNION ALL
    /* 2)  Bounces --------------------------------------------------------- */
    SELECT
        'bounce'                      AS event_type,
        "CAMPAIGN_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "USER_ID"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_BOUNCE_VIEW"
    WHERE "TIME" >= 1685606400
      AND "TIME" <  1685610000

    UNION ALL
    /* 3)  Opens (tapped notifications) ------------------------------------ */
    SELECT
        'open'                        AS event_type,
        "CAMPAIGN_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "USER_ID"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_OPEN_VIEW"
    WHERE "TIME" >= 1685606400
      AND "TIME" <  1685610000

    UNION ALL
    /* 4)  Influenced-opens (app opened shortly after delivery) ------------ */
    SELECT
        'influenced_open'             AS event_type,
        "CAMPAIGN_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "USER_ID"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_INFLUENCEDOPEN_VIEW"
    WHERE "TIME" >= 1685606400
      AND "TIME" <  1685610000
)
/* ---------------------------------------------------------------------------
   Aggregate results
--------------------------------------------------------------------------- */
SELECT
    "CAMPAIGN_ID",
    "MESSAGE_VARIATION_ID",
    "PLATFORM",
    /* Totals -------------------------------------------------------------- */
    SUM(CASE WHEN event_type = 'send'            THEN 1 ELSE 0 END) AS "push_notification_sends",
    SUM(CASE WHEN event_type = 'bounce'          THEN 1 ELSE 0 END) AS "push_notification_bounced",
    SUM(CASE WHEN event_type = 'open'            THEN 1 ELSE 0 END) AS "push_notification_opened",
    SUM(CASE WHEN event_type = 'influenced_open' THEN 1 ELSE 0 END) AS "push_notification_influenced_open",
    /* Unique-user counts -------------------------------------------------- */
    COUNT(DISTINCT CASE WHEN event_type = 'send'            THEN "USER_ID" END) AS "unique_push_notification_sends",
    COUNT(DISTINCT CASE WHEN event_type = 'bounce'          THEN "USER_ID" END) AS "unique_push_notification_bounced",
    COUNT(DISTINCT CASE WHEN event_type = 'open'            THEN "USER_ID" END) AS "unique_push_notification_opened",
    COUNT(DISTINCT CASE WHEN event_type = 'influenced_open' THEN "USER_ID" END) AS "unique_push_notification_influenced_open"
FROM all_events
GROUP BY
    "CAMPAIGN_ID",
    "MESSAGE_VARIATION_ID",
    "PLATFORM"
ORDER BY
    "push_notification_sends" DESC NULLS LAST,
    "CAMPAIGN_ID",
    "MESSAGE_VARIATION_ID";