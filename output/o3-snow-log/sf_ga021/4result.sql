/*  Two–week retention for every “*_quickplay” event that first occurred
    between 02-Jul-2018 and 16-Jul-2018, limited to users that opened at
    least one session (“session_start”) in the same period                           */

WITH union_events AS (      ---------------------------------------------------------
    /* All events we need – 2-Jul thru 30-Jul 2018 (14-day look-ahead)              */
    SELECT
        "user_pseudo_id",
        "event_name",
        TO_DATE("event_date",'YYYYMMDD')         AS event_date_dt
    FROM (
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180702" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180703" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180704" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180705" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180706" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180707" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180708" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180709" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180710" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180711" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180712" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180713" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180714" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180715" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180716" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180717" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180718" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180719" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180720" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180721" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180722" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180723" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180724" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180725" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180726" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180727" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180728" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180729" UNION ALL
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180730"
    )
    WHERE "event_name" IN (
            'session_start',
            'level_start_quickplay',
            'level_end_quickplay',
            'level_fail_quickplay'
          )
),

cohort_users AS (           ---------------------------------------------------------
    /* Users who opened a session during the target 2-Jul-18 ‑ 16-Jul-18 window      */
    SELECT DISTINCT "user_pseudo_id"
    FROM   union_events
    WHERE  "event_name" = 'session_start'
      AND  event_date_dt BETWEEN '2018-07-02'::DATE AND '2018-07-16'::DATE
),

initial_quickplay AS (      ---------------------------------------------------------
    /* First occurrence of every quickplay event for every cohort user in window     */
    SELECT
        e."user_pseudo_id",
        e."event_name"                         AS quickplay_event_name,
        MIN(e.event_date_dt)                   AS first_quickplay_date
    FROM   union_events e
    JOIN   cohort_users c
           ON c."user_pseudo_id" = e."user_pseudo_id"
    WHERE  e."event_name" LIKE '%quickplay'
      AND  e.event_date_dt BETWEEN '2018-07-02'::DATE AND '2018-07-16'::DATE
    GROUP  BY e."user_pseudo_id", e."event_name"
),

retention AS (              ---------------------------------------------------------
    /* Did the same user fire the same quickplay event exactly 14 days later?        */
    SELECT
        i."user_pseudo_id",
        i.quickplay_event_name,
        i.first_quickplay_date,
        CASE
            WHEN EXISTS (
                    SELECT 1
                    FROM   union_events e2
                    WHERE  e2."user_pseudo_id" = i."user_pseudo_id"
                      AND  e2."event_name"     = i.quickplay_event_name
                      AND  e2.event_date_dt    = DATEADD(day,14,i.first_quickplay_date)
            )
            THEN 1 ELSE 0
        END                                      AS retained_flag
    FROM   initial_quickplay i
)

SELECT  --------------------------------------------------------------------------
    quickplay_event_name                              AS quickplay_event,
    COUNT(*)                                          AS initial_users,
    SUM(retained_flag)                                AS users_retained_day_14,
    ROUND(SUM(retained_flag) * 100.0 / COUNT(*),4)    AS retention_rate_pct
FROM   retention
GROUP  BY quickplay_event_name
ORDER  BY retention_rate_pct DESC NULLS LAST;