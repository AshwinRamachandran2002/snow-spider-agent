/* ----------------------------------------------------------
   GA4 public game data – 4-week retention by weekly cohorts
   (cohorts start Monday, first cohort 2018-07-02)
-----------------------------------------------------------*/
WITH "ALL_SESSIONS" AS (

    /* =================  2018-07  ================= */
    SELECT TO_DATE("event_date",'YYYYMMDD') AS "event_date", "user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180702" WHERE "event_name" = 'session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180703" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180704" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180705" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180706" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180707" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180708" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180709" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180710" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180711" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180712" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180713" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180714" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180715" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180716" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180717" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180718" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180719" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180720" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180721" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180722" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180723" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180724" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180725" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180726" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180727" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180728" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180729" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180730" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180731" WHERE "event_name"='session_start'

    /* =================  2018-08  ================= */
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180816" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180817" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180818" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180819" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180821" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180822" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180823" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180824" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180825" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180826" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180828" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180829" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180830" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180831" WHERE "event_name"='session_start'

    /* =================  2018-09  ================= */
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930" WHERE "event_name"='session_start'

    /* =================  2018-10  ================= */
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002" WHERE "event_name"='session_start'
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"user_pseudo_id" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181003" WHERE "event_name"='session_start'
),

/* first session ever per user */
"FIRST_SESSIONS" AS (
  SELECT  "user_pseudo_id",
          MIN("event_date") AS "first_session_date"
  FROM    "ALL_SESSIONS"
  GROUP BY "user_pseudo_id"
),

/* cohort assignment (Monday of first week) – only cohorts whose 4-week
   window is fully inside the data set (≤ 2018-09-03) are retained      */
"COHORTED_USERS" AS (
  SELECT  "user_pseudo_id",
          DATE_TRUNC('WEEK',"first_session_date") AS "cohort_monday"
  FROM    "FIRST_SESSIONS"
  WHERE   "first_session_date" >= '2018-07-02'
          AND DATE_TRUNC('WEEK',"first_session_date") <= '2018-09-03'
),

/* 4-week retention */
"RETENTION" AS (
  SELECT
        cu."cohort_monday",
        COUNT(DISTINCT cu."user_pseudo_id") AS "cohort_size",
        COUNT(DISTINCT CASE
              WHEN s."event_date"
                     BETWEEN DATEADD('day',21,cu."cohort_monday")
                         AND DATEADD('day',27,cu."cohort_monday")
              THEN cu."user_pseudo_id" END)   AS "retained_week4"
  FROM        "COHORTED_USERS" cu
  LEFT JOIN   "ALL_SESSIONS"   s
         ON   s."user_pseudo_id" = cu."user_pseudo_id"
  GROUP BY    cu."cohort_monday"
)

/* cohort (Monday) with the highest 4-week retention rate */
SELECT TO_CHAR("cohort_monday",'YYYY-MM-DD') AS "YYYY-MM-DD"
FROM   "RETENTION"
ORDER  BY ("retained_week4"::FLOAT / NULLIF("cohort_size",0)) DESC NULLS LAST
LIMIT  1;