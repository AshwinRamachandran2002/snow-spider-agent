/*  User-engagement with push notifications between 08:00 – 09:00 UTC on 2023-06-01
    Metrics returned per campaign & platform:
      • push_notification_sends / unique_push_notification_sends
      • push_notification_open  / unique_push_notification_opened
      • push_notification_bounced / unique_push_notification_bounced
      • push_notification_influenced_open / unique_push_notification_influenced_open
*/
SELECT
        s."CAMPAIGN_ID",
        s."PLATFORM",
        COUNT(*)                                   AS "push_notification_sends",
        COUNT(DISTINCT s."USER_ID")                AS "unique_push_notification_sends",
        COUNT(o."ID")                              AS "push_notification_open",
        COUNT(DISTINCT o."USER_ID")                AS "unique_push_notification_opened",
        COUNT(b."ID")                              AS "push_notification_bounced",
        COUNT(DISTINCT b."USER_ID")                AS "unique_push_notification_bounced",
        COUNT(i."MESSAGE_VARIATION_ID")            AS "push_notification_influenced_open",
        COUNT(DISTINCT i."USER_ID")                AS "unique_push_notification_influenced_open"
FROM   BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_SEND_VIEW"            s
LEFT   JOIN BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_OPEN_VIEW"       o
       ON  s."USER_ID"              = o."USER_ID"
       AND s."MESSAGE_VARIATION_ID" = o."MESSAGE_VARIATION_ID"
       AND o."TIME"                >= 1685606400          -- 2023-06-01 08:00:00 UTC
       AND o."TIME"                 < 1685610000          -- 2023-06-01 09:00:00 UTC
LEFT   JOIN BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_BOUNCE_VIEW"     b
       ON  s."USER_ID"              = b."USER_ID"
       AND s."MESSAGE_VARIATION_ID" = b."MESSAGE_VARIATION_ID"
       AND b."TIME"                >= 1685606400
       AND b."TIME"                 < 1685610000
LEFT   JOIN BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_INFLUENCEDOPEN_VIEW" i
       ON  s."USER_ID"              = i."USER_ID"
       AND s."MESSAGE_VARIATION_ID" = i."MESSAGE_VARIATION_ID"
       AND i."TIME"                >= 1685606400
       AND i."TIME"                 < 1685610000
WHERE  s."TIME" >= 1685606400
  AND  s."TIME" < 1685610000
GROUP  BY
        s."CAMPAIGN_ID",
        s."PLATFORM"
ORDER  BY
        "push_notification_sends" DESC NULLS LAST;