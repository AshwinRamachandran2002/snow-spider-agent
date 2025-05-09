/* ---------------------------------------------------------------------
   Push-notification engagement between 08:00 and 09:00 UTC on 2023-06-01
---------------------------------------------------------------------*/
WITH
/* ---------- 1. Window boundaries ---------- */
time_window AS (
    SELECT
        1685606400 AS "start_epoch",   -- 2023-06-01 08:00:00 UTC
        1685610000 AS "end_epoch"      -- 2023-06-01 09:00:00 UTC
),

/* ---------- 2. Send events (regular + shared) ---------- */
send_events AS (
    SELECT
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "USER_ID",
        "MESSAGE_VARIATION_ID"              AS "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "AD_TRACKING_ENABLED"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_SEND_VIEW, time_window tw
    WHERE "TIME" BETWEEN tw."start_epoch" AND tw."end_epoch" - 1

    UNION ALL

    SELECT
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "USER_ID",
        "MESSAGE_VARIATION_API_ID"          AS "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "AD_TRACKING_ENABLED"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_SEND_SHARED_VIEW, time_window tw
    WHERE "TIME" BETWEEN tw."start_epoch" AND tw."end_epoch" - 1
),

/* ---------- 3. Bounce events (regular + shared) ---------- */
bounce_events AS (
    SELECT
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "USER_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "AD_TRACKING_ENABLED"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_BOUNCE_VIEW, time_window tw
    WHERE "TIME" BETWEEN tw."start_epoch" AND tw."end_epoch" - 1

    UNION ALL

    SELECT
        NULL                                  AS "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "USER_ID",
        "MESSAGE_VARIATION_API_ID"            AS "MESSAGE_VARIATION_ID",
        "PLATFORM",
        NULL                                  AS "AD_TRACKING_ENABLED"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_BOUNCE_SHARED_VIEW, time_window tw
    WHERE "TIME" BETWEEN tw."start_epoch" AND tw."end_epoch" - 1
),

/* ---------- 4. Open events (regular, iOS-foreground, shared) ---------- */
open_events AS (
    SELECT
        COALESCE("APP_GROUP_ID", NULL)        AS "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "USER_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "AD_TRACKING_ENABLED"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_OPEN_VIEW, time_window tw
    WHERE "TIME" BETWEEN tw."start_epoch" AND tw."end_epoch" - 1

    UNION ALL
    SELECT
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "USER_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "AD_TRACKING_ENABLED"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_IOSFOREGROUND_VIEW, time_window tw
    WHERE "TIME" BETWEEN tw."start_epoch" AND tw."end_epoch" - 1

    UNION ALL
    SELECT
        NULL                                   AS "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "USER_ID",
        "MESSAGE_VARIATION_API_ID"             AS "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "AD_TRACKING_ENABLED"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_OPEN_SHARED_VIEW, time_window tw
    WHERE "TIME" BETWEEN tw."start_epoch" AND tw."end_epoch" - 1

    UNION ALL
    SELECT
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "USER_ID",
        "MESSAGE_VARIATION_API_ID"             AS "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "AD_TRACKING_ENABLED"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_IOSFOREGROUND_SHARED_VIEW, time_window tw
    WHERE "TIME" BETWEEN tw."start_epoch" AND tw."end_epoch" - 1
),

/* ---------- 5. Influenced-open events (regular + shared) ---------- */
infl_events AS (
    SELECT
        NULL                                   AS "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "USER_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        NULL                                   AS "AD_TRACKING_ENABLED"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_INFLUENCEDOPEN_VIEW, time_window tw
    WHERE "TIME" BETWEEN tw."start_epoch" AND tw."end_epoch" - 1

    UNION ALL
    SELECT
        NULL                                   AS "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "USER_ID",
        "MESSAGE_VARIATION_API_ID"             AS "MESSAGE_VARIATION_ID",
        "PLATFORM",
        NULL                                   AS "AD_TRACKING_ENABLED"
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_INFLUENCEDOPEN_SHARED_VIEW, time_window tw
    WHERE "TIME" BETWEEN tw."start_epoch" AND tw."end_epoch" - 1
),

/* ---------- 6. Dimension set (app-group / campaign / variation / platform / ad-tracking) ---------- */
dim AS (
    SELECT DISTINCT
        "APP_GROUP_ID",
        "CAMPAIGN_ID",
        "MESSAGE_VARIATION_ID",
        "PLATFORM",
        "AD_TRACKING_ENABLED"
    FROM (
        SELECT * FROM send_events
        UNION ALL
        SELECT * FROM bounce_events
        UNION ALL
        SELECT * FROM open_events
        UNION ALL
        SELECT * FROM infl_events
    )
),

/* ---------- 7. Metric aggregations ---------- */
send_agg AS (
    SELECT
        "APP_GROUP_ID","CAMPAIGN_ID","MESSAGE_VARIATION_ID","PLATFORM","AD_TRACKING_ENABLED",
        COUNT(*)                    AS "push_notification_sends",
        COUNT(DISTINCT "USER_ID")   AS "unique_push_notification_sends"
    FROM send_events
    GROUP BY 1,2,3,4,5
),
bounce_agg AS (
    SELECT
        "APP_GROUP_ID","CAMPAIGN_ID","MESSAGE_VARIATION_ID","PLATFORM","AD_TRACKING_ENABLED",
        COUNT(*)                    AS "push_notification_bounced",
        COUNT(DISTINCT "USER_ID")   AS "unique_push_notification_bounced"
    FROM bounce_events
    GROUP BY 1,2,3,4,5
),
open_agg AS (
    SELECT
        "APP_GROUP_ID","CAMPAIGN_ID","MESSAGE_VARIATION_ID","PLATFORM","AD_TRACKING_ENABLED",
        COUNT(*)                    AS "push_notification_open",
        COUNT(DISTINCT "USER_ID")   AS "unique_push_notification_opened"
    FROM open_events
    GROUP BY 1,2,3,4,5
),
infl_agg AS (
    SELECT
        "APP_GROUP_ID","CAMPAIGN_ID","MESSAGE_VARIATION_ID","PLATFORM","AD_TRACKING_ENABLED",
        COUNT(*)                    AS "push_notification_influenced_open",
        COUNT(DISTINCT "USER_ID")   AS "unique_push_notification_influenced_open"
    FROM infl_events
    GROUP BY 1,2,3,4,5
)

/* ---------- 8. Final result ---------- */
SELECT
    d."APP_GROUP_ID",
    d."CAMPAIGN_ID",
    d."MESSAGE_VARIATION_ID",
    d."PLATFORM",
    d."AD_TRACKING_ENABLED",
    COALESCE(s."push_notification_sends",0)                   AS "push_notification_sends",
    COALESCE(s."unique_push_notification_sends",0)            AS "unique_push_notification_sends",
    COALESCE(b."push_notification_bounced",0)                 AS "push_notification_bounced",
    COALESCE(b."unique_push_notification_bounced",0)          AS "unique_push_notification_bounced",
    COALESCE(o."push_notification_open",0)                    AS "push_notification_open",
    COALESCE(o."unique_push_notification_opened",0)           AS "unique_push_notification_opened",
    COALESCE(i."push_notification_influenced_open",0)         AS "push_notification_influenced_open",
    COALESCE(i."unique_push_notification_influenced_open",0)  AS "unique_push_notification_influenced_open"
FROM dim d
LEFT JOIN send_agg  s ON d."APP_GROUP_ID"          IS NOT DISTINCT FROM s."APP_GROUP_ID"
                     AND d."CAMPAIGN_ID"           =  s."CAMPAIGN_ID"
                     AND d."MESSAGE_VARIATION_ID"  =  s."MESSAGE_VARIATION_ID"
                     AND d."PLATFORM"              =  s."PLATFORM"
                     AND d."AD_TRACKING_ENABLED"   IS NOT DISTINCT FROM s."AD_TRACKING_ENABLED"
LEFT JOIN bounce_agg b ON d."APP_GROUP_ID"          IS NOT DISTINCT FROM b."APP_GROUP_ID"
                      AND d."CAMPAIGN_ID"           =  b."CAMPAIGN_ID"
                      AND d."MESSAGE_VARIATION_ID"  =  b."MESSAGE_VARIATION_ID"
                      AND d."PLATFORM"              =  b."PLATFORM"
                      AND d."AD_TRACKING_ENABLED"   IS NOT DISTINCT FROM b."AD_TRACKING_ENABLED"
LEFT JOIN open_agg   o ON d."APP_GROUP_ID"          IS NOT DISTINCT FROM o."APP_GROUP_ID"
                      AND d."CAMPAIGN_ID"           =  o."CAMPAIGN_ID"
                      AND d."MESSAGE_VARIATION_ID"  =  o."MESSAGE_VARIATION_ID"
                      AND d."PLATFORM"              =  o."PLATFORM"
                      AND d."AD_TRACKING_ENABLED"   IS NOT DISTINCT FROM o."AD_TRACKING_ENABLED"
LEFT JOIN infl_agg   i ON d."APP_GROUP_ID"          IS NOT DISTINCT FROM i."APP_GROUP_ID"
                      AND d."CAMPAIGN_ID"           =  i."CAMPAIGN_ID"
                      AND d."MESSAGE_VARIATION_ID"  =  i."MESSAGE_VARIATION_ID"
                      AND d."PLATFORM"              =  i."PLATFORM"
                      AND d."AD_TRACKING_ENABLED"   IS NOT DISTINCT FROM i."AD_TRACKING_ENABLED"
ORDER BY "push_notification_sends" DESC NULLS LAST;