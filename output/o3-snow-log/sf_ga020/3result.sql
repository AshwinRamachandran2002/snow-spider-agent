/*  Lowest week-2 retention rate among quick-play event types
    – Cohort: users whose FIRST quick-play event occurred 01-15 Aug 2018
    – Retention: at least one “session_start” event 7-13 days after cohort day
*/
WITH aug_events AS (   -- 01-15 Aug, 4 columns
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815"
),
cohort AS (              -- first quick-play per user
    SELECT  "user_pseudo_id",
            "event_name"                     AS "quickplay_type",
            TO_DATE("event_date",'YYYYMMDD') AS cohort_day,
            ROW_NUMBER() OVER (PARTITION BY "user_pseudo_id"
                               ORDER BY "event_timestamp")             AS rn
    FROM aug_events
    WHERE "event_name" ILIKE '%quickplay%'
),
denom AS (               -- cohort size
    SELECT "quickplay_type",
           COUNT(DISTINCT "user_pseudo_id") AS users_initial
    FROM cohort
    WHERE rn = 1
    GROUP BY 1
),
session_events AS (      -- 01-31 Aug session_start
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') AS sess_day
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180816" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180817" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180818" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180819" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180821" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180822" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180823" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180824" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180825" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180826" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180828" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180829" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180830" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id", TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180831" WHERE "event_name"='session_start'
),
retained AS (            -- users with session_start 7-13 days after cohort
    SELECT DISTINCT c."quickplay_type", c."user_pseudo_id"
    FROM cohort c
    JOIN session_events s
         ON c."user_pseudo_id" = s."user_pseudo_id"
    WHERE c.rn = 1
      AND DATEDIFF('day', c.cohort_day, s.sess_day) BETWEEN 7 AND 13
)
SELECT   d."quickplay_type",
         d.users_initial,
         COUNT(DISTINCT r."user_pseudo_id")                       AS users_retained_week2,
         ROUND(COUNT(DISTINCT r."user_pseudo_id") /
               NULLIF(d.users_initial,0)::FLOAT , 4)              AS retention_rate
FROM     denom d
LEFT JOIN retained r
       ON d."quickplay_type" = r."quickplay_type"
GROUP BY 1,2
ORDER BY retention_rate ASC NULLS LAST
LIMIT 1;