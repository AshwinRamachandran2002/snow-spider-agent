/*  Push‑notification engagement between 08:00‑09:00 UTC, 1‑Jun‑2023  */
WITH
bounds AS (
    SELECT
        1685606400 ::NUMBER AS start_epoch ,   -- 2023‑06‑01 08:00:00 UTC
        1685610000 ::NUMBER AS end_epoch       -- 2023‑06‑01 09:00:00 UTC
),

/* ------------------------------------------------------------------ */
/* 1) union all relevant push‑notification events                      */
/* ------------------------------------------------------------------ */
events AS (

    /* sends --------------------------------------------------------- */
    SELECT
        s."APP_GROUP_ID",
        s."CAMPAIGN_ID",
        s."MESSAGE_VARIATION_ID",
        s."PLATFORM",
        s."AD_TRACKING_ENABLED",
        s."USER_ID",
        'send'      AS event_type
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_SEND_VIEW" s , bounds b
    WHERE s."TIME" BETWEEN b.start_epoch AND b.end_epoch - 1

    UNION ALL

    /* bounces ------------------------------------------------------- */
    SELECT
        bnc."APP_GROUP_ID",
        bnc."CAMPAIGN_ID",
        bnc."MESSAGE_VARIATION_ID",
        bnc."PLATFORM",
        bnc."AD_TRACKING_ENABLED",
        bnc."USER_ID",
        'bounce'    AS event_type
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_BOUNCE_VIEW" bnc , bounds b
    WHERE bnc."TIME" BETWEEN b.start_epoch AND b.end_epoch - 1

    UNION ALL

    /* opens --------------------------------------------------------- */
    SELECT
        op."APP_GROUP_ID",
        op."CAMPAIGN_ID",
        op."MESSAGE_VARIATION_ID",
        op."PLATFORM",
        op."AD_TRACKING_ENABLED",
        op."USER_ID",
        'open'      AS event_type
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_OPEN_VIEW" op , bounds b
    WHERE op."TIME" BETWEEN b.start_epoch AND b.end_epoch - 1

    UNION ALL

    /* influenced opens --------------------------------------------- */
    SELECT
        inf."APP_GROUP_ID",
        inf."CAMPAIGN_ID",
        inf."MESSAGE_VARIATION_ID",
        inf."PLATFORM",
        /*  column not present in this view – supply NULL              */
        NULL        AS "AD_TRACKING_ENABLED",
        inf."USER_ID",
        'influenced_open' AS event_type
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_INFLUENCEDOPEN_VIEW" inf , bounds b
    WHERE inf."TIME" BETWEEN b.start_epoch AND b.end_epoch - 1
)

/* ------------------------------------------------------------------ */
/* 2) aggregate metrics                                                */
/* ------------------------------------------------------------------ */
SELECT
    "APP_GROUP_ID",
    "CAMPAIGN_ID",
    "MESSAGE_VARIATION_ID",
    "PLATFORM",
    "AD_TRACKING_ENABLED",

    /* raw event counts --------------------------------------------- */
    COUNT_IF(event_type = 'send')               AS push_notification_sends,
    COUNT_IF(event_type = 'bounce')             AS push_notification_bounced,
    COUNT_IF(event_type = 'open')               AS push_notification_open,
    COUNT_IF(event_type = 'influenced_open')    AS push_notification_influenced_open,

    /* unique‑user counts ------------------------------------------- */
    COUNT(DISTINCT CASE WHEN event_type = 'send'            THEN "USER_ID" END)
        AS unique_push_notification_sends,
    COUNT(DISTINCT CASE WHEN event_type = 'bounce'          THEN "USER_ID" END)
        AS unique_push_notification_bounced,
    COUNT(DISTINCT CASE WHEN event_type = 'open'            THEN "USER_ID" END)
        AS unique_push_notification_opened,
    COUNT(DISTINCT CASE WHEN event_type = 'influenced_open' THEN "USER_ID" END)
        AS unique_push_notification_influenced_open
FROM events
GROUP BY
    "APP_GROUP_ID",
    "CAMPAIGN_ID",
    "MESSAGE_VARIATION_ID",
    "PLATFORM",
    "AD_TRACKING_ENABLED"
ORDER BY
    push_notification_sends DESC NULLS LAST,
    "APP_GROUP_ID",
    "CAMPAIGN_ID";