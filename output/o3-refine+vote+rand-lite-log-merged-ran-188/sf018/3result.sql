/*-----------------------------------------------
  Examine user engagement with push notifications
  for the one-hour window 08:00-09:00 UTC on
  1-Jun-2023 (Unix epoch 1 685 606 400–1 685 610 000)
------------------------------------------------*/

WITH window AS (
    SELECT
        1685606400::NUMBER AS "start_ts",
        1685610000::NUMBER AS "end_ts"
),

/* --- Push-notification SEND events ------------------------------- */
sends AS (
    SELECT
        "CAMPAIGN_ID",
        COUNT(*)                     AS "push_notification_sends",
        COUNT(DISTINCT "USER_ID")    AS "unique_push_notification_sends"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_SEND_VIEW, window
    WHERE "TIME" >= "start_ts"
      AND "TIME" <  "end_ts"
    GROUP BY "CAMPAIGN_ID"
),

/* --- Push-notification BOUNCE events ----------------------------- */
bounces AS (
    SELECT
        "CAMPAIGN_ID",
        COUNT(*)                     AS "push_notification_bounced",
        COUNT(DISTINCT "USER_ID")    AS "unique_push_notification_bounced"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_BOUNCE_VIEW, window
    WHERE "TIME" >= "start_ts"
      AND "TIME" <  "end_ts"
    GROUP BY "CAMPAIGN_ID"
),

/* --- Push-notification OPEN events ------------------------------- */
opens AS (
    SELECT
        "CAMPAIGN_ID",
        COUNT(*)                     AS "push_notification_open",
        COUNT(DISTINCT "USER_ID")    AS "unique_push_notification_opened"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_OPEN_VIEW, window
    WHERE "TIME" >= "start_ts"
      AND "TIME" <  "end_ts"
    GROUP BY "CAMPAIGN_ID"
),

/* --- Push-notification INFLUENCED OPEN events -------------------- */
influenced AS (
    SELECT
        "CAMPAIGN_ID",
        COUNT(*)                     AS "push_notification_influenced_open",
        COUNT(DISTINCT "USER_ID")    AS "unique_push_notification_influenced_open"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_INFLUENCEDOPEN_VIEW, window
    WHERE "TIME" >= "start_ts"
      AND "TIME" <  "end_ts"
    GROUP BY "CAMPAIGN_ID"
)

/* --- Combine all metrics ---------------------------------------- */
SELECT
    COALESCE(s."CAMPAIGN_ID",
             b."CAMPAIGN_ID",
             o."CAMPAIGN_ID",
             i."CAMPAIGN_ID")                                           AS "CAMPAIGN_ID",
    COALESCE(s."push_notification_sends",                 0)            AS "push_notification_sends",
    COALESCE(s."unique_push_notification_sends",          0)            AS "unique_push_notification_sends",
    COALESCE(b."push_notification_bounced",               0)            AS "push_notification_bounced",
    COALESCE(b."unique_push_notification_bounced",        0)            AS "unique_push_notification_bounced",
    COALESCE(o."push_notification_open",                  0)            AS "push_notification_open",
    COALESCE(o."unique_push_notification_opened",         0)            AS "unique_push_notification_opened",
    COALESCE(i."push_notification_influenced_open",       0)            AS "push_notification_influenced_open",
    COALESCE(i."unique_push_notification_influenced_open",0)            AS "unique_push_notification_influenced_open"
FROM sends        s
FULL OUTER JOIN bounces    b ON s."CAMPAIGN_ID" = b."CAMPAIGN_ID"
FULL OUTER JOIN opens      o ON COALESCE(s."CAMPAIGN_ID", b."CAMPAIGN_ID") = o."CAMPAIGN_ID"
FULL OUTER JOIN influenced i ON COALESCE(s."CAMPAIGN_ID", b."CAMPAIGN_ID", o."CAMPAIGN_ID") = i."CAMPAIGN_ID"
ORDER BY "push_notification_sends" DESC NULLS LAST,
         "CAMPAIGN_ID";