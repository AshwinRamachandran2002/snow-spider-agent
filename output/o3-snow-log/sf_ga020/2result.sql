/*  Which quick-play event had the worst 2-nd-week retention?               */
/*  – Cohort: users whose FIRST quick-play event occurred 1-15 Aug 2018     */
/*  – Retention: had any session_start 8-14 days after that first activity  */

WITH quickplay AS (      -- every quick-play event 1–15 Aug
          SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') AS "evt_d"
            FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801" WHERE "event_name" ILIKE '%quickplay%'
 UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802" WHERE "event_name" ILIKE '%quickplay%'
 UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803" WHERE "event_name" ILIKE '%quickplay%'
 UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804" WHERE "event_name" ILIKE '%quickplay%'
 UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805" WHERE "event_name" ILIKE '%quickplay%'
 UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806" WHERE "event_name" ILIKE '%quickplay%'
 UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807" WHERE "event_name" ILIKE '%quickplay%'
 UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808" WHERE "event_name" ILIKE '%quickplay%'
 UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809" WHERE "event_name" ILIKE '%quickplay%'
 UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810" WHERE "event_name" ILIKE '%quickplay%'
 UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811" WHERE "event_name" ILIKE '%quickplay%'
 UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812" WHERE "event_name" ILIKE '%quickplay%'
 UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813" WHERE "event_name" ILIKE '%quickplay%'
 UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814" WHERE "event_name" ILIKE '%quickplay%'
 UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815" WHERE "event_name" ILIKE '%quickplay%'
),
first_q AS (            -- first day each user triggered each quick-play event type
    SELECT "user_pseudo_id",
           "event_name" AS "first_q_type",
           MIN("evt_d") AS "first_q_date"
    FROM quickplay
    GROUP BY "user_pseudo_id","event_name"
),
sessions AS (           -- all session_start events 16–29 Aug
          SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') AS "sess_d"
            FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180816" WHERE "event_name"='session_start'
 UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180817" WHERE "event_name"='session_start'
 UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180818" WHERE "event_name"='session_start'
 UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180819" WHERE "event_name"='session_start'
 UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820" WHERE "event_name"='session_start'
 UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180821" WHERE "event_name"='session_start'
 UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180822" WHERE "event_name"='session_start'
 UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180823" WHERE "event_name"='session_start'
 UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180824" WHERE "event_name"='session_start'
 UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180825" WHERE "event_name"='session_start'
 UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180826" WHERE "event_name"='session_start'
 UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827" WHERE "event_name"='session_start'
 UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180828" WHERE "event_name"='session_start'
 UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180829" WHERE "event_name"='session_start'
),
retention AS (          -- calculate cohort size & retained users
    SELECT f."first_q_type",
           COUNT(DISTINCT f."user_pseudo_id")                                                       AS "cohort_users",
           COUNT(DISTINCT CASE WHEN DATEDIFF(day,f."first_q_date",s."sess_d") BETWEEN 8 AND 14
                                THEN s."user_pseudo_id" END)                                        AS "retained_users"
    FROM first_q f
    LEFT JOIN sessions s
           ON f."user_pseudo_id" = s."user_pseudo_id"
    GROUP BY f."first_q_type"
)
SELECT "first_q_type",
       "cohort_users",
       "retained_users",
       ROUND("retained_users"*100.0/NULLIF("cohort_users",0),2) AS "retention_pct"
FROM   retention
ORDER  BY "retention_pct" ASC NULLS LAST
LIMIT  1;