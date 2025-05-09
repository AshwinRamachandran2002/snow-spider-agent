/* -----------------------------------------------------------
   7-day (Monday-based) retention for users whose FIRST
   session_start happened during 02-Jul-2018 → 08-Jul-2018.
   Week-0 = 02-Jul-2018 … 08-Jul-2018
   Retention observed only with events dated ≤ 02-Oct-2018
----------------------------------------------------------------*/
WITH cohort_events AS (          -- all events for the 7 cohort-creation days
    SELECT "event_date","user_pseudo_id","event_name" FROM (
        SELECT "event_date","user_pseudo_id","event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180702"
        UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180703"
        UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180704"
        UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180705"
        UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180706"
        UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180707"
        UNION ALL SELECT "event_date","user_pseudo_id","event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180708"
    )
    WHERE "event_name" = 'session_start'
),
cohort AS (                     -- each user’s very first session_start in the week
    SELECT
        "user_pseudo_id",
        MIN("event_date") AS "cohort_start"
    FROM cohort_events
    GROUP BY "user_pseudo_id"
),
events_all AS (                 -- EVERY event produced up to (and incl.) 02-Oct-2018
    SELECT "event_date","user_pseudo_id" FROM (
        /*  -----  July 2018  ------------------------------------------------ */
        SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180702"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180703"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180704"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180705"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180706"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180707"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180708"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180709"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180710"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180711"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180712"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180713"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180714"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180715"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180716"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180717"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180718"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180719"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180720"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180721"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180722"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180723"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180724"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180725"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180726"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180727"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180728"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180729"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180730"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180731"
        /*  -----  August 2018  ---------------------------------------------- */
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180801"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180802"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180803"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180804"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180805"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180806"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180807"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180808"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180809"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180810"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180811"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180812"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180813"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180814"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180815"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180816"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180817"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180818"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180819"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180820"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180821"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180822"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180823"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180824"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180825"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180826"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180827"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180828"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180829"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180830"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180831"
        /*  -----  September 2018  ------------------------------------------- */
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180901"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180902"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180903"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180904"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180905"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180906"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180907"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180908"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180909"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180910"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180911"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180912"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180913"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180914"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180915"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180916"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180917"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180918"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180919"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180920"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180921"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180922"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180923"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180924"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180925"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180926"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180927"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180928"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180929"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180930"
        /*  -----  October 2018 (up to 02-Oct)  ------------------------------- */
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20181001"
        UNION ALL SELECT "event_date","user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20181002"
    )
    WHERE "event_date" <= '20181002'
),
ret AS (                        -- compute Monday-based week index for every visit
    SELECT
        c."user_pseudo_id",
        FLOOR( (TO_DATE(e."event_date",'YYYYMMDD')
              - TO_DATE(c."cohort_start",'YYYYMMDD')) / 7 ) AS "wk_index"
    FROM cohort            c
    JOIN events_all        e  ON e."user_pseudo_id" = c."user_pseudo_id"
)
SELECT
    COUNT(DISTINCT CASE WHEN "wk_index" = 0 THEN "user_pseudo_id" END) AS "week_0_new_users",
    COUNT(DISTINCT CASE WHEN "wk_index" = 1 THEN "user_pseudo_id" END) AS "week_1_retained",
    COUNT(DISTINCT CASE WHEN "wk_index" = 2 THEN "user_pseudo_id" END) AS "week_2_retained",
    COUNT(DISTINCT CASE WHEN "wk_index" = 3 THEN "user_pseudo_id" END) AS "week_3_retained",
    COUNT(DISTINCT CASE WHEN "wk_index" = 4 THEN "user_pseudo_id" END) AS "week_4_retained"
FROM ret;