/* -------------------------------------------------------------------------
   Examine user engagement with push notifications that occurred between
   08:00 UTC and 09:00 UTC on 01-Jun-2023 (epoch 1685606400 – 1685610000).

   The query produces one row per combination of
       APP_GROUP_ID · CAMPAIGN_ID · USER_ID · MESSAGE_VARIATION_ID · PLATFORM
   and returns consolidated counts for:
       – sends
       – bounces
       – opens
       – influenced opens
   together with key user-/device-level context.
------------------------------------------------------------------------- */
WITH
/* 1 ───────────────────────────────── PUSH NOTIFICATION SENDS ───────────────── */
send_events AS (
    SELECT
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "USER_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "AD_TRACKING_ENABLED",
        COUNT(*)                     AS "push_notification_sends"
    FROM   BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_SEND_VIEW
    WHERE  "TIME" BETWEEN 1685606400 AND 1685610000
    GROUP  BY
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "USER_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "AD_TRACKING_ENABLED"
),

/* 2 ───────────────────────────────── PUSH NOTIFICATION BOUNCES ─────────────── */
bounce_events AS (
    SELECT
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "USER_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "AD_TRACKING_ENABLED",
        COUNT(*)                     AS "push_notification_bounced"
    FROM   BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_BOUNCE_VIEW
    WHERE  "TIME" BETWEEN 1685606400 AND 1685610000
    GROUP  BY
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "USER_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "AD_TRACKING_ENABLED"
),

/* 3 ───────────────────────────────── PUSH NOTIFICATION OPENS ───────────────── */
open_events AS (
    SELECT
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "USER_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "AD_TRACKING_ENABLED",
        MAX("DEVICE_MODEL")          AS "DEVICE_MODEL",
        MAX("CARRIER")               AS "CARRIER",
        MAX("BROWSER")               AS "BROWSER",
        COUNT(*)                     AS "push_notification_open"
    FROM   BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_OPEN_VIEW
    WHERE  "TIME" BETWEEN 1685606400 AND 1685610000
    GROUP  BY
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "USER_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "AD_TRACKING_ENABLED"
),

/* 4 ─────────────────────────────── INFLUENCED OPENS ────────────────────────── */
influenced_open_events AS (
    SELECT
        /* This view does not include APP_GROUP_ID or AD_TRACKING_ENABLED */
        NULL                         AS "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "USER_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        NULL                         AS "AD_TRACKING_ENABLED",
        COUNT(*)                     AS "push_notification_influenced_open"
    FROM   BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_INFLUENCEDOPEN_VIEW
    WHERE  "TIME" BETWEEN 1685606400 AND 1685610000
    GROUP  BY
        "CAMPAIGN_ID",
        "USER_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM"
)

/* 5 ──────────────────────────────── CONSOLIDATED VIEW ──────────────────────── */
SELECT
    /* dimensional columns */
    COALESCE(s."APP_GROUP_ID",  b."APP_GROUP_ID",  o."APP_GROUP_ID",  i."APP_GROUP_ID")                 AS "APP_GROUP_ID",
    COALESCE(s."CAMPAIGN_ID",   b."CAMPAIGN_ID",   o."CAMPAIGN_ID",   i."CAMPAIGN_ID")                  AS "CAMPAIGN_ID",
    COALESCE(s."USER_ID",       b."USER_ID",       o."USER_ID",       i."USER_ID")                      AS "USER_ID",
    COALESCE(s."MESSAGE_VARIATION_ID", b."MESSAGE_VARIATION_ID", o."MESSAGE_VARIATION_ID", i."MESSAGE_VARIATION_ID")
                                                                                                        AS "MESSAGE_VARIATION_ID",
    COALESCE(s."PLATFORM",      b."PLATFORM",      o."PLATFORM",      i."PLATFORM")                     AS "PLATFORM",
    COALESCE(s."AD_TRACKING_ENABLED", b."AD_TRACKING_ENABLED", o."AD_TRACKING_ENABLED", i."AD_TRACKING_ENABLED")
                                                                                                        AS "AD_TRACKING_ENABLED",
    /* device context (only present for open events) */
    o."DEVICE_MODEL",
    o."CARRIER",
    o."BROWSER",

    /* engagement metrics */
    COALESCE(s."push_notification_sends",           0) AS "push_notification_sends",
    COALESCE(b."push_notification_bounced",         0) AS "push_notification_bounced",
    COALESCE(o."push_notification_open",            0) AS "push_notification_open",
    COALESCE(i."push_notification_influenced_open", 0) AS "push_notification_influenced_open"
FROM   send_events                AS s
FULL   OUTER JOIN bounce_events   AS b
       ON  s."APP_GROUP_ID"         = b."APP_GROUP_ID"
       AND s."CAMPAIGN_ID"          = b."CAMPAIGN_ID"
       AND s."USER_ID"              = b."USER_ID"
       AND s."MESSAGE_VARIATION_ID" = b."MESSAGE_VARIATION_ID"
       AND s."PLATFORM"             = b."PLATFORM"
FULL   OUTER JOIN open_events     AS o
       ON  COALESCE(s."APP_GROUP_ID",  b."APP_GROUP_ID")          = o."APP_GROUP_ID"
       AND COALESCE(s."CAMPAIGN_ID",   b."CAMPAIGN_ID")           = o."CAMPAIGN_ID"
       AND COALESCE(s."USER_ID",       b."USER_ID")               = o."USER_ID"
       AND COALESCE(s."MESSAGE_VARIATION_ID", b."MESSAGE_VARIATION_ID")
                                                                  = o."MESSAGE_VARIATION_ID"
       AND COALESCE(s."PLATFORM",      b."PLATFORM")              = o."PLATFORM"
FULL   OUTER JOIN influenced_open_events AS i
       ON  COALESCE(s."CAMPAIGN_ID",   b."CAMPAIGN_ID",   o."CAMPAIGN_ID")   = i."CAMPAIGN_ID"
       AND COALESCE(s."USER_ID",       b."USER_ID",       o."USER_ID")       = i."USER_ID"
       AND COALESCE(s."MESSAGE_VARIATION_ID", b."MESSAGE_VARIATION_ID", o."MESSAGE_VARIATION_ID")
                                                                             = i."MESSAGE_VARIATION_ID"
       AND COALESCE(s."PLATFORM",      b."PLATFORM",      o."PLATFORM")      = i."PLATFORM"
ORDER BY
    "APP_GROUP_ID",
    "CAMPAIGN_ID",
    "USER_ID",
    "MESSAGE_VARIATION_ID",
    "PLATFORM";