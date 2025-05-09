WITH all_events AS (
    SELECT
        "user_pseudo_id"            AS user_id,
        "event_date"                AS event_date,   -- rename without quotes for later use
        "event_name"                AS event_name
    FROM (
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180702" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180703" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180704" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180705" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180706" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180707" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180708" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180709" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180710" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180711" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180712" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180713" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180714" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180715" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180716" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180717" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180718" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180719" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180720" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180721" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180722" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180723" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180724" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180725" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180726" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180727" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180728" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180729" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180730" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180731" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180816" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180817" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180818" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180819" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180821" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180822" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180823" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180824" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180825" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180826" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180828" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180829" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180830" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180831" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002" UNION ALL
        SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181003"
    )
),
sessions AS (
    SELECT
        user_id,
        TO_DATE(event_date, 'YYYYMMDD') AS event_dt
    FROM all_events
    WHERE event_name = 'session_start'
      AND TO_DATE(event_date, 'YYYYMMDD') >= '2018-07-02'
),
first_sessions AS (
    SELECT
        user_id,
        MIN(event_dt) AS first_session_dt
    FROM sessions
    GROUP BY user_id
),
cohort_users AS (
    SELECT
        user_id,
        DATE_TRUNC('WEEK', first_session_dt) AS cohort_monday
    FROM first_sessions
),
retention_calc AS (
    SELECT
        cu.cohort_monday,
        COUNT(DISTINCT cu.user_id) AS cohort_size,
        COUNT(DISTINCT CASE
                           WHEN s.event_dt BETWEEN cu.cohort_monday + 21
                                               AND     cu.cohort_monday + 27
                           THEN cu.user_id
                       END) AS retained_users
    FROM cohort_users cu
    LEFT JOIN sessions s
           ON s.user_id = cu.user_id
    GROUP BY cu.cohort_monday
),
cohort_rates AS (
    SELECT
        cohort_monday,
        retained_users / cohort_size::FLOAT AS week4_retention
    FROM retention_calc
    WHERE cohort_size > 0
)
SELECT TO_CHAR(cohort_monday, 'YYYY-MM-DD') AS "YYYY-MM-DD"
FROM cohort_rates
ORDER BY week4_retention DESC NULLS LAST
LIMIT 1;