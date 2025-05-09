/*----------------------------------------------------------
  Two–week retention for each “*_quickplay” event
  Cohort       : users whose FIRST *_quickplay event occurred
                 between 2-Jul-2018 and 16-Jul-2018 (inclusive)
                 AND who had a session_start in the same period
  Retained user: user who fires the SAME *_quickplay event again
                 exactly 14 days after the cohort date
----------------------------------------------------------*/
WITH events AS (      -- ❶  Load raw events needed (2-Jul-2018 → 30-Jul-2018)
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180702" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180703" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180704" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180705" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180706" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180707" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180708" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180709" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180710" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180711" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180712" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180713" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180714" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180715" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180716" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180717" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180718" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180719" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180720" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180721" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180722" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180723" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180724" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180725" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180726" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180727" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180728" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180729" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180730"
),
/* ❷ Users with at least one session_start in the cohort window */
session_users AS (
    SELECT DISTINCT "user_pseudo_id"
    FROM   events
    WHERE  "event_name" = 'session_start'
      AND  TO_DATE("event_date",'YYYYMMDD') BETWEEN '2018-07-02' AND '2018-07-16'
),
/* ❸ First *_quickplay event per user within the window 2-Jul → 16-Jul */
initial_quickplay AS (
    SELECT
        "user_pseudo_id",
        "event_name"                AS quickplay_event,
        TO_DATE("event_date",'YYYYMMDD') AS cohort_date,
        ROW_NUMBER() OVER (PARTITION BY "user_pseudo_id","event_name"
                           ORDER BY "event_timestamp")          AS rn
    FROM   events
    WHERE  "event_name" ILIKE '%\_quickplay'      -- quickplay events
      AND  TO_DATE("event_date",'YYYYMMDD') BETWEEN '2018-07-02' AND '2018-07-16'
      AND  "user_pseudo_id" IN (SELECT "user_pseudo_id" FROM session_users)
    QUALIFY rn = 1                                 -- keep the first one
),
/* ❹ Users who repeat the SAME quickplay event exactly 14 days later */
retained_users AS (
    SELECT DISTINCT
        iq."user_pseudo_id",
        iq.quickplay_event
    FROM   initial_quickplay   iq
    JOIN   events              e
           ON  e."user_pseudo_id" = iq."user_pseudo_id"
           AND e."event_name"    = iq.quickplay_event
           AND TO_DATE(e."event_date",'YYYYMMDD')
               = DATEADD(day,14,iq.cohort_date)
)
/* ❺ Final retention calculation */
SELECT
    iq.quickplay_event,
    COUNT(DISTINCT iq."user_pseudo_id")                     AS cohort_users,
    COUNT(DISTINCT ru."user_pseudo_id")                     AS retained_users,
    ROUND(
        COUNT(DISTINCT ru."user_pseudo_id")::FLOAT
        / NULLIF(COUNT(DISTINCT iq."user_pseudo_id"),0)
        ,4)                                                 AS two_week_retention_rate
FROM   initial_quickplay iq
LEFT   JOIN retained_users ru
       ON  ru.quickplay_event = iq.quickplay_event
       AND ru."user_pseudo_id" = iq."user_pseudo_id"
GROUP  BY iq.quickplay_event
ORDER  BY two_week_retention_rate DESC NULLS LAST;