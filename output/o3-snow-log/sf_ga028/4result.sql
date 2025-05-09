/* -------------------------------------------------
   7-day (weekly) retention for the cohort whose
   first-ever session_start occurred Mon-Sun,
   02-Jul-2018 → 08-Jul-2018   (Week-0)

   Output columns
     week0_new_users   – cohort size
     week1_retained    – users active 09-Jul → 15-Jul
     week2_retained    – users active 16-Jul → 22-Jul
     week3_retained    – users active 23-Jul → 29-Jul
     week4_retained    – users active 30-Jul → 05-Aug
---------------------------------------------------*/
WITH all_events AS (          /* every event through 02-Oct-2018 */
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
    SELECT "user_pseudo_id","event_date","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002"
),
/* ---- users’ FIRST-EVER session_start date ---- */
first_sessions AS (
    SELECT "user_pseudo_id",
           MIN("event_date") AS "first_session_date"
    FROM all_events
    WHERE "event_name" = 'session_start'
    GROUP BY "user_pseudo_id"
),
/* ---- cohort = first session during 02-Jul → 08-Jul ---- */
cohort AS (
    SELECT "user_pseudo_id"
    FROM first_sessions
    WHERE "first_session_date" BETWEEN '20180702' AND '20180708'
),
/* activity of those cohort users in each of the 5 weeks */
week_activity AS (
    SELECT
        e."user_pseudo_id",
        CASE
            WHEN e."event_date" BETWEEN '20180702' AND '20180708' THEN 0
            WHEN e."event_date" BETWEEN '20180709' AND '20180715' THEN 1
            WHEN e."event_date" BETWEEN '20180716' AND '20180722' THEN 2
            WHEN e."event_date" BETWEEN '20180723' AND '20180729' THEN 3
            WHEN e."event_date" BETWEEN '20180730' AND '20180805' THEN 4
        END AS "week_num"
    FROM all_events e
    INNER JOIN cohort c             /* only cohort users */
            ON e."user_pseudo_id" = c."user_pseudo_id"
    /* only need activity in the 5-week window */
    WHERE e."event_date" BETWEEN '20180702' AND '20180805'
),
week_counts AS (
    SELECT "week_num",
           COUNT(DISTINCT "user_pseudo_id") AS "users"
    FROM week_activity
    GROUP BY "week_num"
)
SELECT
    (SELECT COUNT(*) FROM cohort)                                     AS "week0_new_users",
    COALESCE((SELECT "users" FROM week_counts WHERE "week_num" = 1),0) AS "week1_retained",
    COALESCE((SELECT "users" FROM week_counts WHERE "week_num" = 2),0) AS "week2_retained",
    COALESCE((SELECT "users" FROM week_counts WHERE "week_num" = 3),0) AS "week3_retained",
    COALESCE((SELECT "users" FROM week_counts WHERE "week_num" = 4),0) AS "week4_retained";