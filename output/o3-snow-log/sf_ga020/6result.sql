/*-------------------------------------------------------------
   Quick-play 2nd-week retention by event type
   – Cohort : users whose FIRST quick-play event happened
              01-Aug-2018 … 15-Aug-2018 (inclusive)
   – Retained: user fired at least one session_start between
               day 8 and day 14 (inclusive) after that first day
   – Output  : event type with the lowest retention
----------------------------------------------------------------*/
WITH cohort_raw AS (          /* all events 1-15 Aug               */
    SELECT "event_name","user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') AS evt_dt
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801" UNION ALL
    SELECT "event_name","user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802" UNION ALL
    SELECT "event_name","user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803" UNION ALL
    SELECT "event_name","user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804" UNION ALL
    SELECT "event_name","user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805" UNION ALL
    SELECT "event_name","user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806" UNION ALL
    SELECT "event_name","user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807" UNION ALL
    SELECT "event_name","user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808" UNION ALL
    SELECT "event_name","user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809" UNION ALL
    SELECT "event_name","user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810" UNION ALL
    SELECT "event_name","user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811" UNION ALL
    SELECT "event_name","user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812" UNION ALL
    SELECT "event_name","user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813" UNION ALL
    SELECT "event_name","user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814" UNION ALL
    SELECT "event_name","user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815"
), cohort AS (                /* first quick-play date per user     */
    SELECT "event_name",
           "user_pseudo_id",
           MIN(evt_dt) AS first_date
      FROM cohort_raw
     WHERE LOWER("event_name") LIKE '%quickplay%'
     GROUP BY "event_name","user_pseudo_id"
), session_raw AS (           /* every session_start 1-29 Aug       */
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') AS sess_dt
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180816" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180817" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180818" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180819" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180821" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180822" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180823" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180824" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180825" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180826" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180828" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180829" WHERE "event_name"='session_start'
), session_events AS (
    SELECT DISTINCT "user_pseudo_id",sess_dt FROM session_raw
), retained AS (              /* users that returned 8-14 days later */
    SELECT DISTINCT c."event_name",c."user_pseudo_id"
      FROM cohort c
      JOIN session_events s
        ON s."user_pseudo_id" = c."user_pseudo_id"
       AND s.sess_dt BETWEEN DATEADD(day,8,c.first_date)
                         AND DATEADD(day,14,c.first_date)
), summary AS (               /* cohort + retained counts            */
    SELECT c."event_name",
           COUNT(DISTINCT c."user_pseudo_id") AS cohort_users,
           COUNT(DISTINCT r."user_pseudo_id") AS retained_users
      FROM cohort c
      LEFT JOIN retained r
        ON r."event_name" = c."event_name"
       AND r."user_pseudo_id" = c."user_pseudo_id"
     GROUP BY c."event_name"
)
SELECT "event_name"                      AS lowest_retention_event,
       retained_users,
       cohort_users,
       ROUND(retained_users*100.0/cohort_users,2) AS retention_pct
  FROM summary
 ORDER BY retention_pct ASC NULLS LAST
 LIMIT 1;