/*  Weekly cohort-retention (Week-2) from 09-Jul-2018 through 17-Sep-2018  */
WITH all_events AS (

    /* ---------------- July 2018 ---------------- */
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180709" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180710" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180711" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180712" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180713" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180714" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180715" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180716" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180717" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180718" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180719" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180720" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180721" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180722" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180723" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180724" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180725" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180726" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180727" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180728" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180729" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180730" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180731" UNION ALL

    /* ---------------- August 2018 ---------------- */
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180801" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180802" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180803" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180804" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180805" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180806" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180807" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180808" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180809" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180810" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180811" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180812" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180813" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180814" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180815" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180816" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180817" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180818" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180819" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180820" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180821" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180822" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180823" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180824" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180825" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180826" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180827" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180828" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180829" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180830" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180831" UNION ALL

    /* ---------------- September 2018 ---------------- */
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180901" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180902" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180903" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180904" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180905" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180906" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180907" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180908" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180909" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180910" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180911" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180912" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180913" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180914" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180915" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180916" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180917" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180918" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180919" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180920" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180921" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180922" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180923" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180924" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180925" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180926" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180927" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180928" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180929" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM  FIREBASE.ANALYTICS_153293282."EVENTS_20180930" UNION ALL

    /* ---------------- October 2018 ---------------- */
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001" UNION ALL
    SELECT "user_pseudo_id","event_date","user_first_touch_timestamp","event_name"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002"

),

/* -------- identify NEW users (first ever session_start) -------- */
cohort AS (
    SELECT DISTINCT
           "user_pseudo_id",
           DATE_TRUNC('WEEK', TO_DATE("event_date",'YYYYMMDD')) AS cohort_week
    FROM   all_events
    WHERE  "event_name" ILIKE '%session_start%'
      AND  "event_date" = TO_CHAR(TO_DATE(TO_TIMESTAMP("user_first_touch_timestamp"/1000000)),'YYYYMMDD')
),

/* -------- every session_start occurrence -------- */
session_events AS (
    SELECT "user_pseudo_id",
           TO_DATE("event_date",'YYYYMMDD') AS event_dte
    FROM   all_events
    WHERE  "event_name" ILIKE '%session_start%'
)

/* -------- week-2 retention calculation -------- */
SELECT
       c.cohort_week,
       ROUND(
             100.0 * COUNT(DISTINCT CASE
                                        WHEN DATEDIFF('day', c.cohort_week, s.event_dte)
                                             BETWEEN 14 AND 20
                                        THEN s."user_pseudo_id"
                                   END)
             / NULLIF(COUNT(DISTINCT c."user_pseudo_id"),0)
           , 2)  AS week2_retention_pct
FROM   cohort            c
LEFT   JOIN session_events s
       ON c."user_pseudo_id" = s."user_pseudo_id"
WHERE  c.cohort_week BETWEEN '2018-07-09' AND '2018-09-17'
GROUP  BY 1
ORDER  BY 1;