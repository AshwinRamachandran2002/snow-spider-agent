/*  Two-week retention after the first “quickplay” event for users that
    started a session between 2-Jul-2018 and 16-Jul-2018, broken out
    by the type of the initial quickplay event                                    */

WITH all_events AS (
    /* -----------------------------------------------------------------
       Bring in all events from 2-Jul-2018 (cohort start) through
       30-Jul-2018 (last possible 14-day look-back for a 16-Jul cohort) 
    ------------------------------------------------------------------ */
    SELECT TO_DATE("event_date",'YYYYMMDD')  AS "event_date",
           "user_pseudo_id",
           "event_name"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180702"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180703"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180704"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180705"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180706"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180707"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180708"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180709"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180710"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180711"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180712"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180713"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180714"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180715"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180716"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180717"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180718"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180719"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180720"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180721"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180722"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180723"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180724"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180725"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180726"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180727"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180728"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180729"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180730"
),
/* --------------------------------------------------------------------
   Users that opened at least one session in the cohort window
---------------------------------------------------------------------*/
session_users AS (
    SELECT DISTINCT "user_pseudo_id"
    FROM all_events
    WHERE "event_name" = 'session_start'
      AND "event_date" BETWEEN '2018-07-02' AND '2018-07-16'
),
/* --------------------------------------------------------------------
   First quickplay event (per user) inside the cohort window
---------------------------------------------------------------------*/
initial_quickplay AS (
    SELECT "user_pseudo_id",
           "event_name"                 AS "quickplay_type",
           "event_date"                 AS "initial_date"
    FROM (
        SELECT e.*,
               ROW_NUMBER() OVER (PARTITION BY e."user_pseudo_id"
                                  ORDER BY e."event_date") AS rn
        FROM all_events e
        JOIN session_users s
          ON e."user_pseudo_id" = s."user_pseudo_id"
        /* quickplay events end with '_quickplay'  ─ escape '_' */
        WHERE e."event_name" LIKE '%\_quickplay' ESCAPE '\\'
          AND e."event_date" BETWEEN '2018-07-02' AND '2018-07-16'
    )
    WHERE rn = 1
),
/* --------------------------------------------------------------------
   Was the user active exactly 14 days later?
---------------------------------------------------------------------*/
retention_check AS (
    SELECT iq."user_pseudo_id",
           iq."quickplay_type",
           CASE 
               WHEN EXISTS ( SELECT 1
                             FROM all_events ae
                             WHERE ae."user_pseudo_id" = iq."user_pseudo_id"
                               AND ae."event_date" = DATEADD(day,14,iq."initial_date") )
               THEN 1 ELSE 0 
           END                                                AS retained
    FROM initial_quickplay iq
)
/* --------------------------------------------------------------------
   Final 14-day retention summary
---------------------------------------------------------------------*/
SELECT "quickplay_type",
       COUNT(*)                              AS "cohort_size",
       SUM(retained)                         AS "retained_users",
       ROUND( SUM(retained)::FLOAT / 
              NULLIF(COUNT(*),0) , 4)        AS "retention_rate"
FROM   retention_check
GROUP  BY "quickplay_type"
ORDER  BY "retention_rate" DESC NULLS LAST;