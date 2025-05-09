/*  Examine user engagement with push notifications that occurred
    between 08:00 AM UTC and 09:00 AM UTC on 1-Jun-2023.
    Metrics returned per (APP_GROUP_ID, CAMPAIGN_ID):

      • push_notification_sends / unique_push_notification_sends
      • push_notification_bounced / unique_push_notification_bounced
      • push_notification_open   / unique_push_notification_opened
      • push_notification_influenced_open / unique_push_notification_influenced_open
*/
WITH
/* ------------------------------------------------------------- */
/* 1)  Push-notification SEND events                             */
sends AS (
    SELECT
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        COUNT(*)                    AS push_notification_sends,
        COUNT(DISTINCT "USER_ID")   AS unique_push_notification_sends
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_SEND_VIEW"
    WHERE "TIME" >= 1685606400      -- 2023-06-01 08:00:00 UTC
      AND "TIME" <  1685610000      -- 2023-06-01 09:00:00 UTC
    GROUP BY "APP_GROUP_ID", "CAMPAIGN_ID"
),

/* ------------------------------------------------------------- */
/* 2)  Push-notification BOUNCE events                           */
bounces AS (
    SELECT
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        COUNT(*)                    AS push_notification_bounced,
        COUNT(DISTINCT "USER_ID")   AS unique_push_notification_bounced
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_BOUNCE_VIEW"
    WHERE "TIME" >= 1685606400
      AND "TIME" <  1685610000
    GROUP BY "APP_GROUP_ID", "CAMPAIGN_ID"
),

/* ------------------------------------------------------------- */
/* 3)  Push-notification OPEN events                             */
opens AS (
    SELECT
        "CAMPAIGN_ID",
        COUNT(*)                    AS push_notification_open,
        COUNT(DISTINCT "USER_ID")   AS unique_push_notification_opened
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_OPEN_VIEW"
    WHERE "TIME" >= 1685606400
      AND "TIME" <  1685610000
    GROUP BY "CAMPAIGN_ID"
),

/* ------------------------------------------------------------- */
/* 4)  Push-notification INFLUENCED-OPEN events                  */
influenced AS (
    SELECT
        "CAMPAIGN_ID",
        COUNT(*)                    AS push_notification_influenced_open,
        COUNT(DISTINCT "USER_ID")   AS unique_push_notification_influenced_open
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_INFLUENCEDOPEN_VIEW"
    WHERE "TIME" >= 1685606400
      AND "TIME" <  1685610000
    GROUP BY "CAMPAIGN_ID"
),

/* ------------------------------------------------------------- */
/* 5)  Master list of campaigns that had any activity            */
campaigns AS (
    SELECT DISTINCT "APP_GROUP_ID", "CAMPAIGN_ID"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_SEND_VIEW"
    WHERE "TIME" >= 1685606400 AND "TIME" < 1685610000

    UNION

    SELECT DISTINCT "APP_GROUP_ID", "CAMPAIGN_ID"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_BOUNCE_VIEW"
    WHERE "TIME" >= 1685606400 AND "TIME" < 1685610000
)

/* ------------------------------------------------------------- */
SELECT
    c."APP_GROUP_ID",
    c."CAMPAIGN_ID",

    /* Send metrics */
    COALESCE(s.push_notification_sends,                     0) AS push_notification_sends,
    COALESCE(s.unique_push_notification_sends,              0) AS unique_push_notification_sends,

    /* Bounce metrics */
    COALESCE(b.push_notification_bounced,                   0) AS push_notification_bounced,
    COALESCE(b.unique_push_notification_bounced,            0) AS unique_push_notification_bounced,

    /* Open metrics */
    COALESCE(o.push_notification_open,                      0) AS push_notification_open,
    COALESCE(o.unique_push_notification_opened,             0) AS unique_push_notification_opened,

    /* Influenced-open metrics */
    COALESCE(i.push_notification_influenced_open,           0) AS push_notification_influenced_open,
    COALESCE(i.unique_push_notification_influenced_open,    0) AS unique_push_notification_influenced_open

FROM campaigns                      c
LEFT JOIN sends       s ON c."APP_GROUP_ID" = s."APP_GROUP_ID" AND c."CAMPAIGN_ID" = s."CAMPAIGN_ID"
LEFT JOIN bounces     b ON c."APP_GROUP_ID" = b."APP_GROUP_ID" AND c."CAMPAIGN_ID" = b."CAMPAIGN_ID"
LEFT JOIN opens       o ON c."CAMPAIGN_ID"  = o."CAMPAIGN_ID"
LEFT JOIN influenced  i ON c."CAMPAIGN_ID"  = i."CAMPAIGN_ID"

ORDER BY c."APP_GROUP_ID", c."CAMPAIGN_ID";