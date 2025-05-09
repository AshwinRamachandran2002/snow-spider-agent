/*-----------------------------------------------------------
   7-day (Monday-based) weekly retention for the cohort whose
   first session_start happened Mon-02-Jul-2018 – Sun-08-Jul-2018.
   Events are considered only through Tue-02-Oct-2018.
-----------------------------------------------------------*/
WITH all_events AS (          /* explicit UNION – keep only needed cols */
          SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180702"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180703"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180704"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180705"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180706"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180707"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180708"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180709"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180710"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180711"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180712"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180713"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180714"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180715"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180716"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180717"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180718"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180719"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180720"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180721"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180722"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180723"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180724"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180725"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180726"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180727"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180728"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180729"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180730"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180731"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180816"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180817"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180818"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180819"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180821"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180822"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180823"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180824"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180825"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180826"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180828"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180829"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180830"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180831"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001"
 UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002"
),
cohort AS (       /* users whose FIRST session_start is 02-08 Jul 2018 */
    SELECT  "user_pseudo_id",
            MIN("event_date") AS "first_session_date"
    FROM    all_events
    WHERE   "event_name" = 'session_start'
    GROUP BY "user_pseudo_id"
    HAVING  MIN("event_date") BETWEEN '20180702' AND '20180708'
),
user_weeks AS (   /* distinct (user , week_offset) 0-4 */
    SELECT DISTINCT
           e."user_pseudo_id",
           DATEDIFF(
               'week',
               DATE_TRUNC('week', TO_DATE(c."first_session_date",'YYYYMMDD')),
               DATE_TRUNC('week', TO_DATE(e."event_date",'YYYYMMDD'))
           ) AS week_offset
    FROM   all_events e
    JOIN   cohort      c ON e."user_pseudo_id" = c."user_pseudo_id"
    WHERE  e."event_date" <= '20181002'
),
weekly_retention AS (
    SELECT  week_offset,
            COUNT(DISTINCT "user_pseudo_id") AS retained_users
    FROM    user_weeks
    WHERE   week_offset BETWEEN 0 AND 4
    GROUP BY week_offset
),
cohort_size AS ( SELECT COUNT(*) AS week0_new_users FROM cohort )

SELECT  wr.week_offset,
        cs.week0_new_users,
        wr.retained_users
FROM    weekly_retention wr
CROSS JOIN cohort_size   cs
ORDER BY wr.week_offset;