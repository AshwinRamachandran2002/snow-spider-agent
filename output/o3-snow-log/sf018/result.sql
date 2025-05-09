/* -----------------------------------------------------------
Examine push-notification engagement between 08:00 and 09:00 UTC
on 01-Jun-2023 (UNIX epoch 1 685 606 400 – 1 685 610 000).

Metrics returned per platform:
  • push_notification_sends                     / unique users sent
  • push_notification_bounced                   / unique users bounced
  • push_notification_open                      / unique users opened
  • push_notification_influenced_open           / unique users influenced-open
------------------------------------------------------------*/
WITH time_window AS (
    SELECT 1685606400 AS start_ts , 1685610000 AS end_ts
),

/* 1 ────────── Sends */
send_events AS (
    SELECT
        "PLATFORM",
        COUNT(*)                       AS push_notification_sends,
        COUNT(DISTINCT "USER_ID")      AS unique_push_notification_sends
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_SEND_VIEW", time_window
    WHERE "TIME" BETWEEN start_ts AND end_ts
    GROUP BY "PLATFORM"
),

/* 2 ────────── Bounces */
bounce_events AS (
    SELECT
        "PLATFORM",
        COUNT(*)                       AS push_notification_bounced,
        COUNT(DISTINCT "USER_ID")      AS unique_push_notification_bounced
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_BOUNCE_VIEW", time_window
    WHERE "TIME" BETWEEN start_ts AND end_ts
    GROUP BY "PLATFORM"
),

/* 3 ────────── Opens */
open_events AS (
    SELECT
        "PLATFORM",
        COUNT(*)                       AS push_notification_open,
        COUNT(DISTINCT "USER_ID")      AS unique_push_notification_opened
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_OPEN_VIEW", time_window
    WHERE "TIME" BETWEEN start_ts AND end_ts
    GROUP BY "PLATFORM"
),

/* 4 ────────── Influenced-opens */
influenced_events AS (
    SELECT
        "PLATFORM",
        COUNT(*)                       AS push_notification_influenced_open,
        COUNT(DISTINCT "USER_ID")      AS unique_push_notification_influenced_open
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC."USERS_MESSAGES_PUSHNOTIFICATION_INFLUENCEDOPEN_VIEW", time_window
    WHERE "TIME" BETWEEN start_ts AND end_ts
    GROUP BY "PLATFORM"
),

/* 5 ────────── Complete platform list to drive outer joins */
platforms AS (
    SELECT "PLATFORM" FROM send_events
    UNION
    SELECT "PLATFORM" FROM bounce_events
    UNION
    SELECT "PLATFORM" FROM open_events
    UNION
    SELECT "PLATFORM" FROM influenced_events
)

/* 6 ────────── Final engagement summary */
SELECT
    p."PLATFORM",
    COALESCE(s.push_notification_sends,                 0) AS push_notification_sends,
    COALESCE(s.unique_push_notification_sends,          0) AS unique_push_notification_sends,
    COALESCE(b.push_notification_bounced,               0) AS push_notification_bounced,
    COALESCE(b.unique_push_notification_bounced,        0) AS unique_push_notification_bounced,
    COALESCE(o.push_notification_open,                  0) AS push_notification_open,
    COALESCE(o.unique_push_notification_opened,         0) AS unique_push_notification_opened,
    COALESCE(i.push_notification_influenced_open,       0) AS push_notification_influenced_open,
    COALESCE(i.unique_push_notification_influenced_open,0) AS unique_push_notification_influenced_open
FROM platforms            p
LEFT JOIN send_events      s ON p."PLATFORM" = s."PLATFORM"
LEFT JOIN bounce_events    b ON p."PLATFORM" = b."PLATFORM"
LEFT JOIN open_events      o ON p."PLATFORM" = o."PLATFORM"
LEFT JOIN influenced_events i ON p."PLATFORM" = i."PLATFORM"
ORDER BY p."PLATFORM" ASC NULLS LAST;