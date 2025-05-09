/* -----------------------------------------------------------
   1.  UNION ALL every daily table first (no filters inside)
   ----------------------------------------------------------- */
WITH all_events AS (
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM (
        SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180612"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180613"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180614"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180615"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180616"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180617"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180618"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180619"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180620"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180621"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180622"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180623"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180624"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180625"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180626"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180627"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180628"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180629"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180630"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180701"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180702"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180703"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180704"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180705"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180706"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180707"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180708"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180709"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180710"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180711"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180712"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180713"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180714"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180715"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180716"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180717"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180718"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180719"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180720"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180721"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180722"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180723"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180724"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180725"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180726"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180727"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180728"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180729"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180730"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180731"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180816"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180817"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180818"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180819"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180821"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180822"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180823"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180824"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180825"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180826"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180828"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180829"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180830"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180831"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181003"
    )
),

/* -----------------------------------------------------------
   2.  First session per user (session_start)
   ----------------------------------------------------------- */
first_sessions AS (
    SELECT
        "user_pseudo_id",
        MIN("event_timestamp") AS first_session_ts
    FROM all_events
    WHERE "event_name" = 'session_start'
    GROUP BY "user_pseudo_id"
),

/* -----------------------------------------------------------
   3.  Cohort week (Monday) – keep only cohorts starting 2018-07-02+
   ----------------------------------------------------------- */
cohorts AS (
    SELECT
        "user_pseudo_id",
        DATE_TRUNC('WEEK', TO_TIMESTAMP_NTZ(first_session_ts/1000000)) AS cohort_monday
    FROM first_sessions
    WHERE DATE_TRUNC('WEEK', TO_TIMESTAMP_NTZ(first_session_ts/1000000)) >= '2018-07-02'
),

/* -----------------------------------------------------------
   4.  Fourth-week window (22-28 days after cohort Monday)
   ----------------------------------------------------------- */
cohort_bounds AS (
    SELECT
        "user_pseudo_id",
        cohort_monday,
        DATEADD('WEEK', 3, cohort_monday) AS wk4_start,
        DATEADD('WEEK', 4, cohort_monday) AS wk4_end
    FROM cohorts
),

/* -----------------------------------------------------------
   5.  Users who returned during their own 4th week
   ----------------------------------------------------------- */
wk4_active AS (
    SELECT DISTINCT
        cb."user_pseudo_id",
        cb.cohort_monday
    FROM cohort_bounds cb
    JOIN all_events ev
      ON ev."user_pseudo_id" = cb."user_pseudo_id"
     AND TO_TIMESTAMP_NTZ(ev."event_timestamp"/1000000) >= cb.wk4_start
     AND TO_TIMESTAMP_NTZ(ev."event_timestamp"/1000000) <  cb.wk4_end
)

/* -----------------------------------------------------------
   6.  Retention computation & best cohort extraction
   ----------------------------------------------------------- */
SELECT
    TO_CHAR(best.cohort_monday,'YYYY-MM-DD') AS "cohort_with_best_4th_week_retention"
FROM (
    SELECT
        cohorts.cohort_monday,
        COUNT(DISTINCT wk4_active."user_pseudo_id")                       AS retained_users,
        COUNT(DISTINCT cohorts."user_pseudo_id")                          AS cohort_size,
        COUNT(DISTINCT wk4_active."user_pseudo_id")::FLOAT
          / NULLIF(COUNT(DISTINCT cohorts."user_pseudo_id"),0)            AS retention_rate
    FROM cohorts
    LEFT JOIN wk4_active
      ON cohorts."user_pseudo_id" = wk4_active."user_pseudo_id"
     AND cohorts.cohort_monday   = wk4_active.cohort_monday
    GROUP BY cohorts.cohort_monday
    ORDER BY retention_rate DESC NULLS LAST
    LIMIT 1
) best;