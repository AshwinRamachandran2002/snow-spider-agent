/* -------------------------------------------------------------------------
   7-day (weekly) retention for users whose FIRST session happened
   during the week that began on Monday-02-Jul-2018 (“Week-0”).

   1)  all_events      – UNION of every daily events table that exists
                         from 12-Jun-2018 through 02-Oct-2018 (inclusive)
   2)  first_sessions  – first calendar day on which each user fired
                         a “session_start” event
   3)  cohort_users    – users whose first session happened between
                         02-Jul-2018 and 08-Jul-2018 (Mon-Sun)
   4)  retained_events – every event fired by those cohort users
                         up to and including 02-Oct-2018
   5)  retention_counts– number of distinct cohort users that came back
                         in Week-0 … Week-4 (Monday-based weeks)
   6)  final SELECT    – presents new-user base (Week-0) and the
                         retained-user counts for Weeks 0-4
-------------------------------------------------------------------------*/
WITH all_events AS (

    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180612"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180613"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180614"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180615"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180616"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180617"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180618"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180619"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180620"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180621"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180622"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180623"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180624"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180625"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180626"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180627"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180628"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180629"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180630"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180701"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180702"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180703"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180704"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180705"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180706"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180707"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180708"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180709"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180710"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180711"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180712"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180713"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180714"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180715"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180716"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180717"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180718"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180719"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180720"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180721"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180722"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180723"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180724"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180725"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180726"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180727"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180728"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180729"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180730"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180731"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180816"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180817"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180818"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180819"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180821"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180822"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180823"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180824"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180825"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180826"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180828"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180829"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180830"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180831"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001"
    UNION ALL SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002"
),

first_sessions AS (
    SELECT
        "user_pseudo_id",
        MIN("event_date") AS first_session_date
    FROM all_events
    WHERE "event_name" = 'session_start'
    GROUP BY "user_pseudo_id"
),

cohort_users AS (
    SELECT "user_pseudo_id"
    FROM   first_sessions
    WHERE  first_session_date BETWEEN '20180702' AND '20180708'   -- week-0 (Mon-Sun)
),

retained_events AS (
    SELECT ae."user_pseudo_id",
           ae."event_date"
    FROM   all_events         ae
    JOIN   cohort_users       cu  ON cu."user_pseudo_id" = ae."user_pseudo_id"
    WHERE  ae."event_date" <= '20181002'                          -- do not look past 02-Oct
),

retention_counts AS (
    SELECT
        CASE DATEDIFF('WEEK',
                      TO_DATE('2018-07-02'),
                      TO_DATE("event_date",'YYYYMMDD'))
             WHEN 0 THEN 'Week_0'
             WHEN 1 THEN 'Week_1'
             WHEN 2 THEN 'Week_2'
             WHEN 3 THEN 'Week_3'
             WHEN 4 THEN 'Week_4'
        END                               AS week_bucket,
        COUNT(DISTINCT "user_pseudo_id")  AS retained_users
    FROM retained_events
    WHERE DATEDIFF('WEEK',
                   TO_DATE('2018-07-02'),
                   TO_DATE("event_date",'YYYYMMDD')) BETWEEN 0 AND 4
    GROUP BY week_bucket
),

base AS (
    SELECT COUNT(*) AS new_users_week0
    FROM   cohort_users
)

SELECT
       rc.week_bucket,
       CASE WHEN rc.week_bucket = 'Week_0'
            THEN b.new_users_week0
       END                        AS new_users_week0,
       rc.retained_users
FROM   retention_counts rc
LEFT   JOIN base b
       ON rc.week_bucket = 'Week_0'
ORDER  BY rc.week_bucket;