/* ------------------------------------------------------------------
   User-engagement with Push Notifications between 08:00-09:00 UTC
   on 01-Jun-2023 (Unix epoch 1 685 606 400 – 1 685 610 000)
-------------------------------------------------------------------*/
WITH one_hour_window AS (
    SELECT 
        1685606400::NUMBER AS "start_ts",   -- 2023-06-01 08:00:00 UTC
        1685610000::NUMBER AS "end_ts"      -- 2023-06-01 09:00:00 UTC
),

/* ----------------------------  SEND  ---------------------------- */
send_events AS (
    /* Send view (has Campaign ID) */
    SELECT "CAMPAIGN_ID", "USER_ID"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_SEND_VIEW", one_hour_window
    WHERE "TIME" BETWEEN "start_ts" AND "end_ts"

    UNION ALL

    /* Shared-send view (no Campaign column → use NULL) */
    SELECT NULL AS "CAMPAIGN_ID", "USER_ID"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_SEND_SHARED_VIEW", one_hour_window
    WHERE "TIME" BETWEEN "start_ts" AND "end_ts"
),

/* ---------------------------  BOUNCE  --------------------------- */
bounce_events AS (
    SELECT "CAMPAIGN_ID", "USER_ID"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_BOUNCE_VIEW", one_hour_window
    WHERE "TIME" BETWEEN "start_ts" AND "end_ts"

    UNION ALL

    SELECT "CAMPAIGN_ID", "USER_ID"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_BOUNCE_SHARED_VIEW", one_hour_window
    WHERE "TIME" BETWEEN "start_ts" AND "end_ts"
),

/* -----------------------------  OPEN  --------------------------- */
open_events AS (
    SELECT "CAMPAIGN_ID", "USER_ID"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_OPEN_VIEW", one_hour_window
    WHERE "TIME" BETWEEN "start_ts" AND "end_ts"

    UNION ALL
    SELECT "CAMPAIGN_ID", "USER_ID"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_IOSFOREGROUND_VIEW", one_hour_window
    WHERE "TIME" BETWEEN "start_ts" AND "end_ts"

    UNION ALL
    SELECT "CAMPAIGN_ID", "USER_ID"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_OPEN_SHARED_VIEW", one_hour_window
    WHERE "TIME" BETWEEN "start_ts" AND "end_ts"

    UNION ALL
    SELECT "CAMPAIGN_ID", "USER_ID"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_IOSFOREGROUND_SHARED_VIEW", one_hour_window
    WHERE "TIME" BETWEEN "start_ts" AND "end_ts"
),

/* ----------------------  INFLUENCED-OPEN  ----------------------- */
influenced_open_events AS (
    SELECT "CAMPAIGN_ID", "USER_ID"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_INFLUENCEDOPEN_VIEW", one_hour_window
    WHERE "TIME" BETWEEN "start_ts" AND "end_ts"

    UNION ALL

    SELECT "CAMPAIGN_ID", "USER_ID"
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_INFLUENCEDOPEN_SHARED_VIEW", one_hour_window
    WHERE "TIME" BETWEEN "start_ts" AND "end_ts"
),

/* ----------------------  METRIC SUMMARIES  ---------------------- */
send_summary AS (
    SELECT "CAMPAIGN_ID",
           COUNT(*)                  AS "push_notification_sends",
           COUNT(DISTINCT "USER_ID") AS "unique_push_notification_sends"
    FROM send_events
    GROUP BY "CAMPAIGN_ID"
),
bounce_summary AS (
    SELECT "CAMPAIGN_ID",
           COUNT(*)                  AS "push_notification_bounced",
           COUNT(DISTINCT "USER_ID") AS "unique_push_notification_bounced"
    FROM bounce_events
    GROUP BY "CAMPAIGN_ID"
),
open_summary AS (
    SELECT "CAMPAIGN_ID",
           COUNT(*)                  AS "push_notification_open",
           COUNT(DISTINCT "USER_ID") AS "unique_push_notification_opened"
    FROM open_events
    GROUP BY "CAMPAIGN_ID"
),
influenced_open_summary AS (
    SELECT "CAMPAIGN_ID",
           COUNT(*)                  AS "push_notification_influenced_open",
           COUNT(DISTINCT "USER_ID") AS "unique_push_notification_influenced_open"
    FROM influenced_open_events
    GROUP BY "CAMPAIGN_ID"
)

/* ---------------------------  OUTPUT  --------------------------- */
SELECT 
       COALESCE(snd."CAMPAIGN_ID",
                opn."CAMPAIGN_ID",
                bnc."CAMPAIGN_ID",
                inf."CAMPAIGN_ID")                         AS "CAMPAIGN_ID",
       snd."push_notification_sends",
       snd."unique_push_notification_sends",
       opn."push_notification_open",
       opn."unique_push_notification_opened",
       bnc."push_notification_bounced",
       bnc."unique_push_notification_bounced",
       inf."push_notification_influenced_open",
       inf."unique_push_notification_influenced_open"
FROM send_summary                 snd
FULL JOIN open_summary            opn ON snd."CAMPAIGN_ID" = opn."CAMPAIGN_ID"
FULL JOIN bounce_summary          bnc ON COALESCE(snd."CAMPAIGN_ID",opn."CAMPAIGN_ID") = bnc."CAMPAIGN_ID"
FULL JOIN influenced_open_summary inf ON COALESCE(snd."CAMPAIGN_ID",opn."CAMPAIGN_ID",bnc."CAMPAIGN_ID") = inf."CAMPAIGN_ID"
ORDER BY snd."push_notification_sends" DESC NULLS LAST;