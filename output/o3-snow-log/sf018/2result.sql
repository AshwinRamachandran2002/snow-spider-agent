/* -----------------------------------------------
   Examine user engagement with push notifications
   between 08:00 – 09:00 (UTC) on 01-Jun-2023
-------------------------------------------------*/
WITH

/* 1) All “send” events in the one-hour window */
send_events AS (
    SELECT
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "USER_ID"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_SEND_VIEW"
    WHERE "TIME" BETWEEN 1685606400 AND 1685610000
),

/* 2) All “bounce” events in the window */
bounce_events AS (
    SELECT
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "USER_ID"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_BOUNCE_VIEW"
    WHERE "TIME" BETWEEN 1685606400 AND 1685610000
),

/* 3) All “open” events in the window */
open_events AS (
    SELECT
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "USER_ID"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_OPEN_VIEW"
    WHERE "TIME" BETWEEN 1685606400 AND 1685610000
),

/* 4) Influenced-open events, matched back to an app-group (if any) */
influenced_open_counts AS (
    SELECT
        COALESCE(s."APP_GROUP_ID", '')          AS "APP_GROUP_ID",
        i."CAMPAIGN_ID",
        i."MESSAGE_VARIATION_ID",
        i."PLATFORM",
        COUNT(*)                                AS push_notification_influenced_open,
        COUNT(DISTINCT i."USER_ID")             AS unique_push_notification_influenced_open
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_INFLUENCEDOPEN_VIEW" i
    LEFT JOIN (   /* distinct key map from sends */
         SELECT DISTINCT
             "APP_GROUP_ID",
             "CAMPAIGN_ID",
             "MESSAGE_VARIATION_ID",
             "PLATFORM"
         FROM send_events
    ) s
      ON  i."CAMPAIGN_ID"         = s."CAMPAIGN_ID"
      AND i."MESSAGE_VARIATION_ID" = s."MESSAGE_VARIATION_ID"
      AND i."PLATFORM"            = s."PLATFORM"
    WHERE i."TIME" BETWEEN 1685606400 AND 1685610000
    GROUP BY 1,2,3,4
),

/* 5) Metric aggregations for each event type */
send_counts AS (
    SELECT
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        COUNT(*)                    AS push_notification_sends,
        COUNT(DISTINCT "USER_ID")   AS unique_push_notification_sends
    FROM send_events
    GROUP BY 1,2,3,4
),

bounce_counts AS (
    SELECT
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        COUNT(*)                    AS push_notification_bounced,
        COUNT(DISTINCT "USER_ID")   AS unique_push_notification_bounced
    FROM bounce_events
    GROUP BY 1,2,3,4
),

open_counts AS (
    SELECT
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        COUNT(*)                    AS push_notification_open,
        COUNT(DISTINCT "USER_ID")   AS unique_push_notification_opened
    FROM open_events
    GROUP BY 1,2,3,4
),

/* 6) Combine all metrics */
all_metrics AS (
    SELECT
        COALESCE(sc."APP_GROUP_ID",  bc."APP_GROUP_ID",
                 oc."APP_GROUP_ID",  ioc."APP_GROUP_ID")  AS "APP_GROUP_ID",
        COALESCE(sc."CAMPAIGN_ID",   bc."CAMPAIGN_ID",
                 oc."CAMPAIGN_ID",   ioc."CAMPAIGN_ID")   AS "CAMPAIGN_ID",
        COALESCE(sc."MESSAGE_VARIATION_ID",  bc."MESSAGE_VARIATION_ID",
                 oc."MESSAGE_VARIATION_ID",  ioc."MESSAGE_VARIATION_ID") AS "MESSAGE_VARIATION_ID",
        COALESCE(sc."PLATFORM", bc."PLATFORM",
                 oc."PLATFORM", ioc."PLATFORM")           AS "PLATFORM",

        sc.push_notification_sends,
        sc.unique_push_notification_sends,

        bc.push_notification_bounced,
        bc.unique_push_notification_bounced,

        oc.push_notification_open,
        oc.unique_push_notification_opened,

        ioc.push_notification_influenced_open,
        ioc.unique_push_notification_influenced_open
    FROM send_counts               sc
    FULL JOIN bounce_counts        bc  USING ("APP_GROUP_ID","CAMPAIGN_ID","MESSAGE_VARIATION_ID","PLATFORM")
    FULL JOIN open_counts          oc  USING ("APP_GROUP_ID","CAMPAIGN_ID","MESSAGE_VARIATION_ID","PLATFORM")
    FULL JOIN influenced_open_counts ioc USING ("APP_GROUP_ID","CAMPAIGN_ID","MESSAGE_VARIATION_ID","PLATFORM")
)

/* 7) Final result */
SELECT
    "APP_GROUP_ID",
    "CAMPAIGN_ID",
    "MESSAGE_VARIATION_ID",
    "PLATFORM",
    COALESCE(push_notification_sends,                     0) AS push_notification_sends,
    COALESCE(unique_push_notification_sends,              0) AS unique_push_notification_sends,
    COALESCE(push_notification_bounced,                   0) AS push_notification_bounced,
    COALESCE(unique_push_notification_bounced,            0) AS unique_push_notification_bounced,
    COALESCE(push_notification_open,                      0) AS push_notification_open,
    COALESCE(unique_push_notification_opened,             0) AS unique_push_notification_opened,
    COALESCE(push_notification_influenced_open,           0) AS push_notification_influenced_open,
    COALESCE(unique_push_notification_influenced_open,    0) AS unique_push_notification_influenced_open
FROM all_metrics
ORDER BY push_notification_sends DESC NULLS LAST,
         "CAMPAIGN_ID",
         "MESSAGE_VARIATION_ID";