WITH union_events AS (
    /* ------------------------------------------------------------
       Combine every daily table and normalise column names
    ------------------------------------------------------------ */
    SELECT "user_pseudo_id"  AS UID ,
           "event_name"      AS EVENT_NAME ,
           TO_DATE("event_date",'YYYYMMDD') AS EVT_DT
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180702"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180703"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180704"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180705"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180706"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180707"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180708"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180709"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180710"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180711"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180712"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180713"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180714"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180715"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180716"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180717"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180718"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180719"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180720"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180721"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180722"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180723"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180724"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180725"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180726"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180727"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180728"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180729"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180730"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180731"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180816"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180817"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180818"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180819"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180821"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180822"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180823"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180824"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180825"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180826"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180828"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180829"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180830"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180831"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181003"
),

/* ------------------------------------------------------------
   Determine first session date for each user (cohort entry)
------------------------------------------------------------ */
first_sessions AS (
    SELECT UID,
           MIN(EVT_DT) AS FIRST_SESSION_DATE
      FROM union_events
     WHERE EVENT_NAME = 'session_start'
       AND EVT_DT >= '2018-07-02'
     GROUP BY UID
),

/* ------------------------------------------------------------
   Assign each user to cohort Monday
------------------------------------------------------------ */
cohorts AS (
    SELECT UID,
           DATE_TRUNC('week', FIRST_SESSION_DATE) AS COHORT_MONDAY
      FROM first_sessions
),

/* ------------------------------------------------------------
   Check whether user generated any event in the 4th week
------------------------------------------------------------ */
retained AS (
    SELECT DISTINCT c.UID,
           c.COHORT_MONDAY
      FROM cohorts      c
      JOIN union_events e
        ON e.UID = c.UID
       AND e.EVT_DT BETWEEN DATEADD(day, 21, c.COHORT_MONDAY)   -- start of 4th week
                        AND DATEADD(day, 27, c.COHORT_MONDAY)   -- end   of 4th week
),

/* ------------------------------------------------------------
   Totals and retained per cohort
------------------------------------------------------------ */
cohort_totals AS (
    SELECT COHORT_MONDAY,
           COUNT(DISTINCT UID) AS TOTAL_USERS
      FROM cohorts
     GROUP BY COHORT_MONDAY
),

cohort_retained AS (
    SELECT COHORT_MONDAY,
           COUNT(DISTINCT UID) AS RETAINED_USERS
      FROM retained
     GROUP BY COHORT_MONDAY
),

/* ------------------------------------------------------------
   Calculate retention rate
------------------------------------------------------------ */
rates AS (
    SELECT t.COHORT_MONDAY,
           r.RETAINED_USERS,
           t.TOTAL_USERS,
           r.RETAINED_USERS * 1.0 / t.TOTAL_USERS AS RETENTION_RATE
      FROM cohort_totals    t
      LEFT JOIN cohort_retained r
        ON t.COHORT_MONDAY = r.COHORT_MONDAY
)

/* ------------------------------------------------------------
   Return Monday date of cohort with highest 4-week retention
------------------------------------------------------------ */
SELECT TO_CHAR(COHORT_MONDAY,'YYYY-MM-DD') AS "cohort_monday_with_highest_4th_week_retention"
  FROM rates
 ORDER BY RETENTION_RATE DESC NULLS LAST,
          COHORT_MONDAY
 LIMIT 1;