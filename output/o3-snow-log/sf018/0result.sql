/*--------------------------------------------------------------
 Examine push-notification engagement between 08:00–09:00 UTC  
 on 01-Jun-2023 (Unix epoch 1 685 616 000 – 1 685 619 600)
--------------------------------------------------------------*/
WITH unified_events AS (
    /* 1️⃣  Push sends */
    SELECT
        'send'                                   AS event_type,
        "APP_GROUP_ID"                           AS app_group_id,
        "CAMPAIGN_ID"                            AS campaign_id,
        "MESSAGE_VARIATION_ID"                   AS message_variation_id,
        "USER_ID"                                AS user_id,
        "PLATFORM"                               AS platform,
        "AD_TRACKING_ENABLED"                    AS ad_tracking_enabled,
        NULL::TEXT                               AS carrier,
        NULL::TEXT                               AS browser,
        NULL::TEXT                               AS device_model
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_SEND_VIEW"
    WHERE "TIME" BETWEEN 1685616000 AND 1685619600

    UNION ALL

    /* 2️⃣  Push bounces */
    SELECT
        'bounce',
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "MESSAGE_VARIATION_ID",
        "USER_ID",
        "PLATFORM",
        "AD_TRACKING_ENABLED",
        NULL::TEXT,
        NULL::TEXT,
        NULL::TEXT
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_BOUNCE_VIEW"
    WHERE "TIME" BETWEEN 1685616000 AND 1685619600

    UNION ALL

    /* 3️⃣  Direct opens */
    SELECT
        'open',
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "MESSAGE_VARIATION_ID",
        "USER_ID",
        "PLATFORM",
        "AD_TRACKING_ENABLED",
        "CARRIER",
        "BROWSER",
        "DEVICE_MODEL"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_OPEN_VIEW"
    WHERE "TIME" BETWEEN 1685616000 AND 1685619600

    UNION ALL

    /* 4️⃣  Influenced opens */
    SELECT
        'influenced_open',
        NULL::TEXT          AS app_group_id,
        "CAMPAIGN_ID",
        "MESSAGE_VARIATION_ID",
        "USER_ID",
        "PLATFORM",
        NULL::BOOLEAN       AS ad_tracking_enabled,
        NULL::TEXT          AS carrier,
        NULL::TEXT          AS browser,
        NULL::TEXT          AS device_model
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_INFLUENCEDOPEN_VIEW"
    WHERE "TIME" BETWEEN 1685616000 AND 1685619600
)

/*--------------------------------------------------------------
 Aggregate engagement metrics
--------------------------------------------------------------*/
SELECT
    app_group_id,
    campaign_id,
    message_variation_id,
    platform,
    MIN(ad_tracking_enabled)                       AS ad_tracking_enabled,
    device_model,
    carrier,
    browser,

    /* volume counts */
    SUM(CASE WHEN event_type = 'send'            THEN 1 ELSE 0 END) AS push_notification_sends,
    COUNT(DISTINCT CASE WHEN event_type = 'send' THEN user_id END)  AS unique_push_notification_sends,

    SUM(CASE WHEN event_type = 'bounce'            THEN 1 ELSE 0 END) AS push_notification_bounced,
    COUNT(DISTINCT CASE WHEN event_type = 'bounce' THEN user_id END)  AS unique_push_notification_bounced,

    SUM(CASE WHEN event_type = 'open'            THEN 1 ELSE 0 END) AS push_notification_open,
    COUNT(DISTINCT CASE WHEN event_type = 'open' THEN user_id END)  AS unique_push_notification_opened,

    SUM(CASE WHEN event_type = 'influenced_open'            THEN 1 ELSE 0 END) AS push_notification_influenced_open,
    COUNT(DISTINCT CASE WHEN event_type = 'influenced_open' THEN user_id END)  AS unique_push_notification_influenced_open
FROM unified_events
GROUP BY
    app_group_id,
    campaign_id,
    message_variation_id,
    platform,
    device_model,
    carrier,
    browser
ORDER BY
    campaign_id,
    message_variation_id,
    platform NULLS LAST;