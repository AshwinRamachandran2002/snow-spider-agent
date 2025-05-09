/*------------------------------------------------------------
  7-day (Monday-based) retention for the cohort whose very first
  “session_start” happened during the week 2-Jul-2018 → 8-Jul-2018
  (Week-0).  Counts are capped to events that occurred no later
  than 2-Oct-2018.
------------------------------------------------------------*/
WITH all_session_starts AS (          -- every session_start up to 2-Oct-2018
    SELECT "event_date",
           "user_pseudo_id"
    FROM  (
           SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180612"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180613"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180614"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180615"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180616"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180617"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180618"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180619"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180620"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180621"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180622"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180623"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180624"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180625"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180626"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180627"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180628"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180629"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180630"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180701"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180702"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180703"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180704"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180705"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180706"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180707"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180708"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180709"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180710"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180711"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180712"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180713"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180714"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180715"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180716"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180717"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180718"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180719"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180720"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180721"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180722"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180723"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180724"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180725"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180726"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180727"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180728"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180729"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180730"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180731"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180816"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180817"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180818"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180819"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180821"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180822"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180823"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180824"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180825"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180826"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180828"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180829"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180830"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180831"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001"
    UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002"
    ) AS u
    WHERE "event_name" = 'session_start'
      AND "event_date" <= '20181002'
),
first_session AS (                   -- earliest session_start per user
    SELECT "user_pseudo_id",
           MIN("event_date") AS first_session_date
    FROM   all_session_starts
    GROUP  BY "user_pseudo_id"
),
week0_cohort AS (                    -- users whose FIRST session is Week-0
    SELECT "user_pseudo_id"
    FROM   first_session
    WHERE  first_session_date BETWEEN '20180702' AND '20180708'
),
retention_counts AS (
    /* Week-0 size */
    SELECT 0 AS week_num,
           COUNT(*) AS users
    FROM   week0_cohort

    UNION ALL
    /* Week-1 : 09-Jul → 15-Jul */
    SELECT 1,
           COUNT(DISTINCT s."user_pseudo_id")
    FROM   all_session_starts s
    JOIN   week0_cohort      c USING ("user_pseudo_id")
    WHERE  s."event_date" BETWEEN '20180709' AND '20180715'

    UNION ALL
    /* Week-2 : 16-Jul → 22-Jul */
    SELECT 2,
           COUNT(DISTINCT s."user_pseudo_id")
    FROM   all_session_starts s
    JOIN   week0_cohort      c USING ("user_pseudo_id")
    WHERE  s."event_date" BETWEEN '20180716' AND '20180722'

    UNION ALL
    /* Week-3 : 23-Jul → 29-Jul */
    SELECT 3,
           COUNT(DISTINCT s."user_pseudo_id")
    FROM   all_session_starts s
    JOIN   week0_cohort      c USING ("user_pseudo_id")
    WHERE  s."event_date" BETWEEN '20180723' AND '20180729'

    UNION ALL
    /* Week-4 : 30-Jul → 05-Aug */
    SELECT 4,
           COUNT(DISTINCT s."user_pseudo_id")
    FROM   all_session_starts s
    JOIN   week0_cohort      c USING ("user_pseudo_id")
    WHERE  s."event_date" BETWEEN '20180730' AND '20180805'
)
SELECT week_num,
       users
FROM   retention_counts
ORDER  BY week_num;