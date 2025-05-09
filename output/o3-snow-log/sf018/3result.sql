/* -----------------------------------------------------------
   Push-notification engagement between 08:00-09:00 01-Jun-2023
   (epoch 1 685 606 400 ≤ TIME < 1 685 610 000)

   Metrics returned per combination of:
     • APP_GROUP_ID
     • CAMPAIGN_ID
     • MESSAGE_VARIATION_ID
     • PLATFORM
     • AD_TRACKING_ENABLED
   Plus the first-available device details coming from the open event.
------------------------------------------------------------*/
WITH one_hour_window AS (
    SELECT
        1685606400 ::NUMBER AS "window_start",   -- 08:00 01-Jun-2023 UTC
        1685610000 ::NUMBER AS "window_end"      -- 09:00 01-Jun-2023 UTC
),

/* 1) Sends -------------------------------------------------*/
send_events AS (
    SELECT
        s."APP_GROUP_ID",
        s."CAMPAIGN_ID",
        s."MESSAGE_VARIATION_ID",
        s."PLATFORM",
        s."AD_TRACKING_ENABLED",
        s."USER_ID"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_SEND_VIEW" s
    CROSS JOIN one_hour_window w
    WHERE s."TIME" >= w."window_start"
      AND s."TIME" <  w."window_end"
),

/* 2) Bounces ----------------------------------------------*/
bounce_events AS (
    SELECT
        b."APP_GROUP_ID",
        b."CAMPAIGN_ID",
        b."MESSAGE_VARIATION_ID",
        b."PLATFORM",
        b."USER_ID"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_BOUNCE_VIEW" b
    CROSS JOIN one_hour_window w
    WHERE b."TIME" >= w."window_start"
      AND b."TIME" <  w."window_end"
),

/* 3) Opens -------------------------------------------------*/
open_events AS (
    SELECT
        o."APP_GROUP_ID",
        o."CAMPAIGN_ID",
        o."MESSAGE_VARIATION_ID",
        o."PLATFORM",
        o."USER_ID",
        o."DEVICE_MODEL",
        o."CARRIER",
        o."BROWSER"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_OPEN_VIEW" o
    CROSS JOIN one_hour_window w
    WHERE o."TIME" >= w."window_start"
      AND o."TIME" <  w."window_end"
),

/* 4) Influenced Opens -------------------------------------*/
infl_open_events AS (
    SELECT
        i."APP_GROUP_ID",
        i."CAMPAIGN_ID",
        i."MESSAGE_VARIATION_ID",
        i."PLATFORM",
        i."USER_ID"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_INFLUENCEDOPEN_VIEW" i
    CROSS JOIN one_hour_window w
    WHERE i."TIME" >= w."window_start"
      AND i."TIME" <  w."window_end"
)

/* 5) Aggregate results ------------------------------------*/
SELECT
    se."APP_GROUP_ID",
    se."CAMPAIGN_ID",
    se."MESSAGE_VARIATION_ID",
    se."PLATFORM",
    se."AD_TRACKING_ENABLED",
    MAX(oe."DEVICE_MODEL") AS "DEVICE_MODEL",
    MAX(oe."CARRIER")      AS "CARRIER",
    MAX(oe."BROWSER")      AS "BROWSER",

    COUNT(*)                                   AS "push_notification_sends",
    COUNT(DISTINCT se."USER_ID")               AS "unique_push_notification_sends",

    COUNT(be."USER_ID")                        AS "push_notification_bounced",
    COUNT(DISTINCT be."USER_ID")               AS "unique_push_notification_bounced",

    COUNT(oe."USER_ID")                        AS "push_notification_open",
    COUNT(DISTINCT oe."USER_ID")               AS "unique_push_notification_opened",

    COUNT(ioe."USER_ID")                       AS "push_notification_influenced_open",
    COUNT(DISTINCT ioe."USER_ID")              AS "unique_push_notification_influenced_open"
FROM        send_events se
LEFT JOIN   bounce_events     be  ON se."APP_GROUP_ID"         = be."APP_GROUP_ID"
                                   AND se."CAMPAIGN_ID"         = be."CAMPAIGN_ID"
                                   AND se."MESSAGE_VARIATION_ID"= be."MESSAGE_VARIATION_ID"
                                   AND se."USER_ID"             = be."USER_ID"
LEFT JOIN   open_events       oe  ON se."APP_GROUP_ID"         = oe."APP_GROUP_ID"
                                   AND se."CAMPAIGN_ID"         = oe."CAMPAIGN_ID"
                                   AND se."MESSAGE_VARIATION_ID"= oe."MESSAGE_VARIATION_ID"
                                   AND se."USER_ID"             = oe."USER_ID"
LEFT JOIN   infl_open_events  ioe ON se."APP_GROUP_ID"         = ioe."APP_GROUP_ID"
                                   AND se."CAMPAIGN_ID"         = ioe."CAMPAIGN_ID"
                                   AND se."MESSAGE_VARIATION_ID"= ioe."MESSAGE_VARIATION_ID"
                                   AND se."USER_ID"             = ioe."USER_ID"
GROUP BY
    se."APP_GROUP_ID",
    se."CAMPAIGN_ID",
    se."MESSAGE_VARIATION_ID",
    se."PLATFORM",
    se."AD_TRACKING_ENABLED"
ORDER BY
    "push_notification_sends" DESC NULLS LAST;