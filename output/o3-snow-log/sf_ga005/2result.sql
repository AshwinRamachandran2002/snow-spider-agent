/*  Weekly-cohort 2-week retention from 09-Jul-2018 to 17-Sep-2018  */
WITH all_events AS (

    /* ---------------------  JUL 2018  --------------------- */
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180709" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180710" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180711" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180712" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180713" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180714" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180715" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180716" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180717" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180718" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180719" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180720" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180721" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180722" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180723" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180724" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180725" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180726" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180727" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180728" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180729" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180730" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180731" UNION ALL

    /* ---------------------  AUG 2018  --------------------- */
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180816" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180817" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180818" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180819" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180821" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180822" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180823" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180824" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180825" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180826" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180828" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180829" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180830" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180831" UNION ALL

    /* ---------------------  SEP 2018  --------------------- */
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930" UNION ALL

    /* ---------------------  OCT 2018  --------------------- */
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181003"
),

session_events AS (
    SELECT
        "user_pseudo_id"                                       AS uid,
        TO_DATE("event_date", 'YYYYMMDD')                      AS evt_date,
        TO_DATE(TO_TIMESTAMP_LTZ("user_first_touch_timestamp" / 1000000)) AS first_touch_date
    FROM all_events
    WHERE "event_name" = 'session_start'
),

cohort_users AS (
    /* first session occurred on first-touch day */
    SELECT
        uid,
        DATE_TRUNC('week', evt_date) AS cohort_week_start
    FROM session_events
    WHERE evt_date = first_touch_date
      AND DATE_TRUNC('week', evt_date) BETWEEN '2018-07-09' AND '2018-09-17'
    GROUP BY uid, cohort_week_start
),

week2_returners AS (
    SELECT DISTINCT
           c.cohort_week_start,
           c.uid
    FROM cohort_users c
    JOIN session_events s
      ON s.uid = c.uid
     AND s.evt_date BETWEEN c.cohort_week_start + 14   /* Mon of week 2 */
                         AND c.cohort_week_start + 20   /* Sun of week 2 */
)

SELECT
    c.cohort_week_start                                 AS cohort_monday,
    COUNT(DISTINCT c.uid)                               AS cohort_users,
    COUNT(DISTINCT w.uid)                               AS week2_returners,
    ROUND( COUNT(DISTINCT w.uid)::FLOAT /
           NULLIF(COUNT(DISTINCT c.uid),0) , 4)         AS week2_retention_rate
FROM cohort_users c
LEFT JOIN week2_returners w
       ON w.cohort_week_start = c.cohort_week_start
GROUP BY c.cohort_week_start
ORDER BY c.cohort_week_start;