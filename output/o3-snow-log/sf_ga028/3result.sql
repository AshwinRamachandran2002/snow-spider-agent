/*--------------------------------------------------------------------
   7–day (weekly) retention for the cohort whose FIRST “session_start”
   happened during the week that begins on Monday-2018-07-02 (07/02-07/08)

   Week_number = DATEDIFF('week' , '2018-07-02' , event_date)
   • Week 0 = cohort-creation week      (07/02-07/08)
   • Week 1 = first full week after     (07/09-07/15)
   • …
   • Week 4 = fourth week after         (07/30-08/05)

   Only events on or before 2018-10-02 are taken into account
--------------------------------------------------------------------*/
WITH all_events AS (
    /* --------  JUNE 2018  -------- */
    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180612" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180613" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180614" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180615" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180616" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180617" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180618" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180619" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180620" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180621" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180622" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180623" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180624" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180625" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180626" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180627" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180628" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180629" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180630" UNION ALL

    /* --------  JULY 2018  -------- */
    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180701" UNION ALL
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

    /* --------  AUGUST 2018  -------- */
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

    /* --------  SEPTEMBER 2018  -------- */
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

    /* --------  OCTOBER 2018 (up to 10/02)  -------- */
    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001" UNION ALL
    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002"
),
/* ----------------------  COHORT  ---------------------- */
cohort AS (
    SELECT
        "user_pseudo_id"
    FROM all_events
    WHERE "event_name" = 'session_start'
    GROUP BY "user_pseudo_id"
    HAVING MIN(TO_DATE("event_date",'YYYYMMDD')) BETWEEN '2018-07-02' AND '2018-07-08'
),
/* ----------------------  ACTIVITY  --------------------- */
activity AS (
    SELECT
        "user_pseudo_id",
        TO_DATE("event_date",'YYYYMMDD') AS "event_dt"
    FROM all_events
    WHERE TO_DATE("event_date",'YYYYMMDD') <= '2018-10-02'
)
/* ----------------------  RESULT  ----------------------- */
SELECT
    0 AS "week_number",
    COUNT(DISTINCT "user_pseudo_id") AS "users"
FROM cohort

UNION ALL

SELECT
    DATEDIFF('week','2018-07-02',activity."event_dt") AS "week_number",
    COUNT(DISTINCT activity."user_pseudo_id")         AS "users"
FROM activity
JOIN cohort
  ON activity."user_pseudo_id" = cohort."user_pseudo_id"
GROUP BY 1
HAVING "week_number" BETWEEN 1 AND 4
ORDER BY 1;