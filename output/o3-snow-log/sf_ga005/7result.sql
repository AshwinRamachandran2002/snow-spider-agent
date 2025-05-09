/*  ----------------------------------------------------------
    Weekly cohort (Mon-Sun) + Week-2 retention for GA4 demo data
    Cohort span  : 09-Jul-2018  → 17-Sep-2018
    Look-back    : session_start of NEW users (event_date = first_touch)
    Retention wk2: session_start in the week that starts 14 days later
    ---------------------------------------------------------- */
WITH all_events AS (      -- 1.  bring all rows we will ever need
    SELECT "event_date",
           "event_name",
           "user_pseudo_id",
           "user_first_touch_timestamp"
    FROM (     /* -------- explicit daily tables, 2018-07-09 … 2018-10-03 -------- */
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180709" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180710" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180711" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180712" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180713" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180714" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180715" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180716" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180717" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180718" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180719" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180720" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180721" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180722" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180723" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180724" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180725" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180726" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180727" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180728" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180729" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180730" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180731" UNION ALL
        /* -----------------   all 31 August days   ----------------- */
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180816" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180817" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180818" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180819" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180821" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180822" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180823" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180824" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180825" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180826" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180828" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180829" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180830" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180831" UNION ALL
        /* -----------------   all 30 September days   ----------------- */
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930" UNION ALL
        /* ------------ first three October days (needed for wk-2 of 17-Sep cohort) ------------ */
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002" UNION ALL
        SELECT "event_date","event_name","user_pseudo_id","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181003"
    )
),
session_start AS (        -- 2. keep only session_start rows, convert to DATEs
    SELECT  TO_DATE("event_date",'YYYYMMDD')                           AS event_dt,
            "user_pseudo_id"                                           AS user_id,
            "user_first_touch_timestamp"
    FROM    all_events
    WHERE   "event_name" = 'session_start'
),
cohort_users AS (          -- 3. new users → cohort they belong to
    SELECT  DISTINCT
            DATE_TRUNC('week', event_dt)           AS cohort_week_start,
            user_id
    FROM    session_start
    WHERE   event_dt = TO_DATE(TO_TIMESTAMP_NTZ("user_first_touch_timestamp" / 1000000))
      AND   DATE_TRUNC('week', event_dt) BETWEEN '2018-07-09' AND '2018-09-17'
),
wk2_returns AS (           -- 4. any return session_start, grouped by week
    SELECT  DISTINCT
            user_id,
            DATE_TRUNC('week', event_dt)           AS week_start
    FROM    session_start
)
-- 5.  Final aggregation: cohort size & week-2 retained users
SELECT  cohort_week_start                                    AS "cohort_week_start",
        COUNT(DISTINCT cu.user_id)                           AS "cohort_users",
        COUNT(DISTINCT CASE
                           WHEN wr.user_id IS NOT NULL THEN cu.user_id
                       END)                                  AS "users_retained_week2",
        ROUND(
            COUNT(DISTINCT CASE WHEN wr.user_id IS NOT NULL THEN cu.user_id END)
            * 100.0
            / COUNT(DISTINCT cu.user_id)
        ,2)                                                  AS "week2_retention_pct"
FROM    cohort_users        cu
LEFT JOIN wk2_returns       wr
       ON wr.user_id   = cu.user_id
      AND wr.week_start = DATEADD(day,14,cu.cohort_week_start)   -- week exactly 2-weeks later
GROUP BY cohort_week_start
ORDER BY cohort_week_start;