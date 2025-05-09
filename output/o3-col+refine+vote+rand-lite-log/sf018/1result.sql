/* --------------------------------------------------------------------
   Examine push-notification engagement between 08:00-09:00 UTC
   on 01-Jun-2023.  The query aggregates, per campaign & platform, the
   volume of sends, bounces, opens and influenced-opens together with
   the corresponding unique-user counts.
--------------------------------------------------------------------*/
WITH event_stream AS (
    /* ------------------------  SEND  ------------------------ */
    SELECT  "TIME",
            "USER_ID",
            "CAMPAIGN_ID",
            "PLATFORM",
            'send' AS "EVENT_TYPE"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_SEND_VIEW"
    
    UNION ALL
    
    /* -----------------------  BOUNCE  ----------------------- */
    SELECT  "TIME",
            "USER_ID",
            "CAMPAIGN_ID",
            "PLATFORM",
            'bounce' AS "EVENT_TYPE"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_BOUNCE_VIEW"
    
    UNION ALL
    
    /* ------------------------  OPEN  ------------------------ */
    SELECT  "TIME",
            "USER_ID",
            "CAMPAIGN_ID",
            "PLATFORM",
            'open' AS "EVENT_TYPE"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_OPEN_VIEW"
    
    UNION ALL
    
    /* ---------------  INFLUENCED OPEN  ---------------------- */
    SELECT  "TIME",
            "USER_ID",
            "CAMPAIGN_ID",
            "PLATFORM",
            'influenced_open' AS "EVENT_TYPE"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_INFLUENCEDOPEN_VIEW"
)

/* ---------------------  FINAL AGGREGATION  ----------------------- */
SELECT
       "CAMPAIGN_ID",
       "PLATFORM",
       /* volumes */
       COUNT_IF("EVENT_TYPE" = 'send')              AS "push_notification_sends",
       COUNT_IF("EVENT_TYPE" = 'bounce')            AS "push_notification_bounced",
       COUNT_IF("EVENT_TYPE" = 'open')              AS "push_notification_open",
       COUNT_IF("EVENT_TYPE" = 'influenced_open')   AS "push_notification_influenced_open",

       /* unique-user counts */
       COUNT(DISTINCT CASE WHEN "EVENT_TYPE" = 'send'            THEN "USER_ID" END) AS "unique_push_notification_sends",
       COUNT(DISTINCT CASE WHEN "EVENT_TYPE" = 'bounce'          THEN "USER_ID" END) AS "unique_push_notification_bounced",
       COUNT(DISTINCT CASE WHEN "EVENT_TYPE" = 'open'            THEN "USER_ID" END) AS "unique_push_notification_opened",
       COUNT(DISTINCT CASE WHEN "EVENT_TYPE" = 'influenced_open' THEN "USER_ID" END) AS "unique_push_notification_influenced_open"

FROM   event_stream
WHERE  "TIME" >= 1685606400          -- 2023-06-01 08:00:00 UTC
  AND  "TIME" <  1685610000          -- 2023-06-01 09:00:00 UTC
GROUP  BY "CAMPAIGN_ID", "PLATFORM"
ORDER  BY "CAMPAIGN_ID" ASC, "PLATFORM" ASC;