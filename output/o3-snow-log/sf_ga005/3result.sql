/*  WEEK-2 RETENTION FOR MONDAY COHORTS
    – first cohort  : 2018-07-09
    – last  cohort  : 2018-09-17   (so that week-2 = 2018-10-01)
*/
WITH events AS (      ---------------------------------------------------- 1. COLLECT EVENTS
    SELECT "event_date","user_pseudo_id","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180709"  UNION ALL
    SELECT "event_date","user_pseudo_id","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180716"  UNION ALL
    SELECT "event_date","user_pseudo_id","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180723"  UNION ALL
    SELECT "event_date","user_pseudo_id","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180730"  UNION ALL
    SELECT "event_date","user_pseudo_id","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806"  UNION ALL
    SELECT "event_date","user_pseudo_id","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813"  UNION ALL
    SELECT "event_date","user_pseudo_id","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820"  UNION ALL
    SELECT "event_date","user_pseudo_id","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827"  UNION ALL
    SELECT "event_date","user_pseudo_id","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903"  UNION ALL
    SELECT "event_date","user_pseudo_id","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910"  UNION ALL
    SELECT "event_date","user_pseudo_id","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917"  UNION ALL
    SELECT "event_date","user_pseudo_id","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924"  UNION ALL
    SELECT "event_date","user_pseudo_id","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001"  UNION ALL
    SELECT "event_date","user_pseudo_id","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002"
),
cohort AS (           ---------------------------------------------------- 2. IDENTIFY NEW-USER COHORTS
    SELECT DISTINCT
           "user_pseudo_id",
           DATE_TRUNC('week', TO_DATE("event_date",'YYYYMMDD')) AS "cohort_week"
    FROM   events
    WHERE  "event_name" = 'session_start'
      AND  "event_date" = TO_CHAR(TO_TIMESTAMP("user_first_touch_timestamp" / 1000000),'YYYYMMDD')
      AND  DATE_TRUNC('week', TO_DATE("event_date",'YYYYMMDD'))
              BETWEEN '2018-07-09' AND '2018-09-17'
),
week2 AS (            ---------------------------------------------------- 3. RETURNS EXACTLY 2 WEEKS LATER
    SELECT DISTINCT e."user_pseudo_id"
    FROM   events e
    JOIN   cohort c
           ON c."user_pseudo_id" = e."user_pseudo_id"
    WHERE  e."event_name" = 'session_start'
      AND  DATE_TRUNC('week', TO_DATE(e."event_date",'YYYYMMDD'))
             = DATEADD('day',14,c."cohort_week")          -- Monday two weeks later
),
retention AS (        ---------------------------------------------------- 4. AGGREGATE
    SELECT
        c."cohort_week",
        COUNT(DISTINCT c."user_pseudo_id")       AS "cohort_size",
        COUNT(DISTINCT w."user_pseudo_id")       AS "week2_users"
    FROM  cohort  c
    LEFT  JOIN week2 w
           ON c."user_pseudo_id" = w."user_pseudo_id"
    GROUP BY c."cohort_week"
)
SELECT
    "cohort_week"                              AS "cohort_monday",
    ROUND("week2_users" * 100.0 / NULLIF("cohort_size",0), 2)
                                               AS "week2_retention_percent"
FROM   retention
ORDER  BY "cohort_week";