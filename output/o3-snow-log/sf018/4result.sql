/* User engagement with push notifications
   during 08:00-09:00 on 01-Jun-2023 (epoch 1685635200–1685638800) */
WITH all_events AS (
    /* -------------------------- SEND events -------------------------- */
    SELECT
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "AD_TRACKING_ENABLED",
        NULL::TEXT  AS "CARRIER",
        NULL::TEXT  AS "BROWSER",
        NULL::TEXT  AS "DEVICE_MODEL",
        "USER_ID",
        'send'      AS "event_type"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_SEND_VIEW"
    WHERE "TIME" BETWEEN 1685635200 AND 1685638800

    UNION ALL

    /* --------------------------- OPEN events ------------------------- */
    SELECT
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "AD_TRACKING_ENABLED",
        "CARRIER",
        "BROWSER",
        "DEVICE_MODEL",
        "USER_ID",
        'open'      AS "event_type"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_OPEN_VIEW"
    WHERE "TIME" BETWEEN 1685635200 AND 1685638800

    UNION ALL

    /* -------------------------- BOUNCE events ------------------------ */
    SELECT
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "AD_TRACKING_ENABLED",
        NULL::TEXT  AS "CARRIER",
        NULL::TEXT  AS "BROWSER",
        NULL::TEXT  AS "DEVICE_MODEL",
        "USER_ID",
        'bounce'    AS "event_type"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_BOUNCE_VIEW"
    WHERE "TIME" BETWEEN 1685635200 AND 1685638800

    UNION ALL

    /* -------------------- INFLUENCED-OPEN events --------------------- */
    SELECT
        NULL::TEXT  AS "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        NULL::BOOLEAN AS "AD_TRACKING_ENABLED",
        NULL::TEXT  AS "CARRIER",
        NULL::TEXT  AS "BROWSER",
        NULL::TEXT  AS "DEVICE_MODEL",
        "USER_ID",
        'influenced_open' AS "event_type"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_INFLUENCEDOPEN_VIEW"
    WHERE "TIME" BETWEEN 1685635200 AND 1685638800
)

/* -------------------------- Aggregation ----------------------------- */
SELECT
    "APP_GROUP_ID",
    "CAMPAIGN_ID",
    "MESSAGE_VARIATION_ID",
    "PLATFORM",
    MAX("AD_TRACKING_ENABLED")                              AS "AD_TRACKING_ENABLED",
    MAX("DEVICE_MODEL")                                     AS "DEVICE_MODEL",
    MAX("CARRIER")                                          AS "CARRIER",
    MAX("BROWSER")                                          AS "BROWSER",

    /* engagement metrics */
    SUM(CASE WHEN "event_type" = 'send'            THEN 1 ELSE 0 END) AS "push_notification_sends",
    COUNT(DISTINCT CASE WHEN "event_type" = 'send' THEN "USER_ID" END) AS "unique_push_notification_sends",

    SUM(CASE WHEN "event_type" = 'bounce'          THEN 1 ELSE 0 END) AS "push_notification_bounced",
    COUNT(DISTINCT CASE WHEN "event_type" = 'bounce' THEN "USER_ID" END) AS "unique_push_notification_bounced",

    SUM(CASE WHEN "event_type" = 'open'            THEN 1 ELSE 0 END) AS "push_notification_open",
    COUNT(DISTINCT CASE WHEN "event_type" = 'open' THEN "USER_ID" END) AS "unique_push_notification_opened",

    SUM(CASE WHEN "event_type" = 'influenced_open' THEN 1 ELSE 0 END) AS "push_notification_influenced_open",
    COUNT(DISTINCT CASE WHEN "event_type" = 'influenced_open' THEN "USER_ID" END) AS "unique_push_notification_influenced_open"
FROM all_events
GROUP BY
    "APP_GROUP_ID",
    "CAMPAIGN_ID",
    "MESSAGE_VARIATION_ID",
    "PLATFORM"
ORDER BY
    "push_notification_sends" DESC NULLS LAST;