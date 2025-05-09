/*  Weekly retention for users whose very first “first_open” occurred
    between 1 Sep 2018 and 7 Sep 2018 (Asia/Shanghai).                   */

WITH EVENTS_UNION AS (
    /* --------------------------------------------------------------- */
    /* All daily tables needed (up to 28-Sep-2018) unioned together.   */
    /* --------------------------------------------------------------- */
    SELECT "user_pseudo_id",
           "event_name",
           "event_timestamp",
           CONVERT_TIMEZONE(
               'UTC',
               'Asia/Shanghai',
               TO_TIMESTAMP("event_timestamp" / 1000000)
           ) AS event_time_sh
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180612" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180613" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180614" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180615" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180616" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180617" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180618" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180619" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180620" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180621" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180622" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180623" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180624" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180625" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180626" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180627" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180628" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180629" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180630" UNION ALL

    /* ---------- July 2018 tables ---------- */
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180701" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180702" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180703" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180704" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180705" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180706" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180707" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180708" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180709" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180710" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180711" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180712" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180713" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180714" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180715" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180716" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180717" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180718" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180719" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180720" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180721" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180722" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180723" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180724" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180725" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180726" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180727" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180728" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180729" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180730" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180731" UNION ALL

    /* ---------- August 2018 tables ---------- */
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180816" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180817" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180818" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180819" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180821" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180822" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180823" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180824" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180825" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180826" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180828" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180829" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180830" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai', TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180831" UNION ALL

    /* ---------- September 2018 tables (up to 28-Sep) ---------- */
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp",
           CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                            TO_TIMESTAMP("event_timestamp"/1000000))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928"
),

/* ---------- first_open (earliest) per user ---------- */
FIRST_OPEN AS (
    SELECT "user_pseudo_id",
           MIN(event_time_sh) AS first_open_time
    FROM EVENTS_UNION
    WHERE "event_name" = 'first_open'
    GROUP BY "user_pseudo_id"
),

/* ---------- cohort: first_open between 1-Sep and 7-Sep 2018 ---------- */
COHORT AS (
    SELECT "user_pseudo_id", first_open_time
    FROM FIRST_OPEN
    WHERE CAST(first_open_time AS DATE) BETWEEN '2018-09-01' AND '2018-09-07'
),

/* ---------- activity within 21 days of first_open -------------------- */
ACTIVITY AS (
    SELECT c."user_pseudo_id",
           c.first_open_time,
           e.event_time_sh
    FROM EVENTS_UNION e
    JOIN COHORT       c
      ON e."user_pseudo_id" = c."user_pseudo_id"
    WHERE DATEDIFF('day',
                   CAST(c.first_open_time AS DATE),
                   CAST(e.event_time_sh  AS DATE)) BETWEEN 1 AND 21
),

/* ---------- assign each return to week index ------------------------- */
USER_WEEK AS (
    SELECT DISTINCT
           "user_pseudo_id",
           CASE
             WHEN DATEDIFF('day', CAST(first_open_time AS DATE),
                                 CAST(event_time_sh  AS DATE)) BETWEEN  1 AND  7 THEN 1
             WHEN DATEDIFF('day', CAST(first_open_time AS DATE),
                                 CAST(event_time_sh  AS DATE)) BETWEEN  8 AND 14 THEN 2
             WHEN DATEDIFF('day', CAST(first_open_time AS DATE),
                                 CAST(event_time_sh  AS DATE)) BETWEEN 15 AND 21 THEN 3
           END AS week_index
    FROM ACTIVITY
),

COHORT_SIZE AS (
    SELECT COUNT(DISTINCT "user_pseudo_id") AS total_users
    FROM COHORT
),

RETAINED AS (
    SELECT week_index,
           COUNT(DISTINCT "user_pseudo_id") AS retained_users
    FROM USER_WEEK
    GROUP BY week_index
),

PIVOTED AS (
    SELECT
        MAX(CASE WHEN week_index = 1 THEN retained_users END) AS week1,
        MAX(CASE WHEN week_index = 2 THEN retained_users END) AS week2,
        MAX(CASE WHEN week_index = 3 THEN retained_users END) AS week3
    FROM RETAINED
)

/* ---------- final retention ratios ---------------------------------- */
SELECT
    ROUND(COALESCE(p.week1, 0) / NULLIF(c.total_users, 0), 4) AS "WEEK1_RETENTION",
    ROUND(COALESCE(p.week2, 0) / NULLIF(c.total_users, 0), 4) AS "WEEK2_RETENTION",
    ROUND(COALESCE(p.week3, 0) / NULLIF(c.total_users, 0), 4) AS "WEEK3_RETENTION"
FROM PIVOTED p
CROSS JOIN COHORT_SIZE c;