/* -------------------------------------------------------------
   Weekly cohort analysis – Week-2 (exactly 14 days) retention
   Cohort Mondays: 09-Jul-2018 … 17-Sep-2018
   Source tables : FIREBASE.ANALYTICS_153293282.EVENTS_YYYYMMDD
----------------------------------------------------------------*/
WITH all_sessions AS (
    /* -----  July 2018  ---------------------------------------*/
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180709" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180710" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180711" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180712" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180713" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180714" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180715" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180716" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180717" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180718" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180719" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180720" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180721" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180722" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180723" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180724" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180725" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180726" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180727" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180728" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180729" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180730" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180731" WHERE "event_name"='session_start' UNION ALL

    /* -----  August 2018  -------------------------------------*/
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180816" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180817" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180818" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180819" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180821" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180822" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180823" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180824" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180825" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180826" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180828" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180829" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180830" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180831" WHERE "event_name"='session_start' UNION ALL

    /* -----  September 2018  ----------------------------------*/
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930" WHERE "event_name"='session_start' UNION ALL

    /* -----  October 2018  (needed for Sep-17 cohort check) ---*/
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001" WHERE "event_name"='session_start' UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002" WHERE "event_name"='session_start'
),

/* convert to real dates and add Monday-week label */
sessions_fmt AS (
    SELECT
        "user_pseudo_id"                                   AS user_id,
        TO_DATE("event_date",'YYYYMMDD')                   AS event_dt,
        TO_DATE(TO_TIMESTAMP("user_first_touch_timestamp"/1000000)) AS first_touch_dt,
        DATE_TRUNC('WEEK',TO_DATE("event_date",'YYYYMMDD')) AS monday_week
    FROM all_sessions
),

/* ------------------------------------------------------------
   1. Build cohort of NEW users (event date == first touch date)
   ------------------------------------------------------------*/
cohort_users AS (
    SELECT
        user_id,
        MIN(monday_week) AS cohort_monday
    FROM sessions_fmt
    WHERE event_dt = first_touch_dt
    GROUP BY user_id
    HAVING cohort_monday BETWEEN '2018-07-09' AND '2018-09-17'
),

/* cohort sizes */
cohort_sizes AS (
    SELECT cohort_monday, COUNT(*) AS cohort_users
    FROM cohort_users
    GROUP BY cohort_monday
),

/* ------------------------------------------------------------
   2. Identify users who returned exactly 14 days later (Monday)
   ------------------------------------------------------------*/
returns_wk2 AS (
    SELECT DISTINCT cu.user_id, cu.cohort_monday
    FROM cohort_users cu
    JOIN sessions_fmt s
      ON s.user_id = cu.user_id
     AND s.event_dt = DATEADD(day,14,cu.cohort_monday)     -- Monday two weeks later
)

/* ------------------------------------------------------------
   3. Final Week-2 retention %
   ------------------------------------------------------------*/
SELECT
    cs.cohort_monday                                AS cohort_week_monday,
    ROUND( ( COALESCE(r.ret_users,0)::FLOAT / cs.cohort_users) * 100 , 2) 
        AS week2_retention_pct
FROM cohort_sizes cs
LEFT JOIN (
    SELECT cohort_monday, COUNT(*) AS ret_users
    FROM returns_wk2
    GROUP BY cohort_monday
) r ON cs.cohort_monday = r.cohort_monday
ORDER BY cohort_week_monday;