/*-----------------------------------------------------------
 Weekly cohort (Mon-Sun) – Week-2 retention
-----------------------------------------------------------*/
WITH all_events AS (
    /* ------------------------------------------------------------------
       Concatenate every daily events table in the required date window
    ------------------------------------------------------------------ */
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180709"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180710"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180711"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180712"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180713"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180714"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180715"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180716"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180717"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180718"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180719"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180720"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180721"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180722"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180723"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180724"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180725"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180726"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180727"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180728"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180729"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180730"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180731"  UNION ALL
    /* ---------- AUGUST 2018 ---------- */
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180816"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180817"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180818"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180819"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180821"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180822"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180823"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180824"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180825"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180826"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180828"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180829"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180830"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180831"  UNION ALL
    /* ---------- SEPTEMBER 2018 ---------- */
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930"  UNION ALL
    /* ---------- OCTOBER 2018 ---------- */
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001"  UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002"
),
/* ------------------------------------------------------------------
   Identify NEW users and assign them to the Monday of their first
   session_start week (the “cohort_date”).
------------------------------------------------------------------ */
cohort_users AS (
    SELECT DISTINCT
           "user_pseudo_id",
           TO_CHAR(DATE_TRUNC('week', TO_DATE("event_date",'YYYYMMDD')), 'YYYYMMDD') AS cohort_date
      FROM all_events
     WHERE "event_name" = 'session_start'
       AND "event_date" = TO_CHAR(
               TO_DATE(TO_TIMESTAMP("user_first_touch_timestamp" / 1000000)),
               'YYYYMMDD'
           )
       AND TO_CHAR(DATE_TRUNC('week', TO_DATE("event_date",'YYYYMMDD')), 'YYYYMMDD')
           BETWEEN '20180709' AND '20180917'
),
/* ------------------------------------------------------------------
   Users who fire at least one session_start in the week that is
   exactly two weeks AFTER their cohort week.
------------------------------------------------------------------ */
retained_users AS (
    SELECT DISTINCT
           c."user_pseudo_id",
           c.cohort_date
      FROM cohort_users c
      JOIN all_events  e
        ON c."user_pseudo_id" = e."user_pseudo_id"
       AND e."event_name"     = 'session_start'
       AND TO_DATE(e."event_date",'YYYYMMDD')
           BETWEEN DATEADD(day,14,TO_DATE(c.cohort_date,'YYYYMMDD'))
               AND  DATEADD(day,20,TO_DATE(c.cohort_date,'YYYYMMDD'))
)
/* ------------------------------------------------------------------
   Final weekly cohort metrics
------------------------------------------------------------------ */
SELECT
       cu.cohort_date                                   AS "cohort_monday",
       COUNT(DISTINCT cu."user_pseudo_id")              AS "cohort_size",
       COUNT(DISTINCT ru."user_pseudo_id")              AS "retained_users_wk2",
       ROUND(
           COUNT(DISTINCT ru."user_pseudo_id") * 100.0
           / NULLIF(COUNT(DISTINCT cu."user_pseudo_id"), 0)
       , 2)                                             AS "week_2_retention_pct"
  FROM cohort_users cu
  LEFT JOIN retained_users ru
    ON cu.cohort_date = ru.cohort_date
 GROUP BY cu.cohort_date
 ORDER BY cu.cohort_date;