/* 7-day (Monday-based) retention for the cohort whose first
   session_start happened during Week-0: 02-Jul-2018 → 08-Jul-2018.
   Events considered only up to 02-Oct-2018. */

WITH
/* -------------------------------------------------- */
/* Week-0 : Mon 02-Jul-2018 – Sun 08-Jul-2018          */
week0 AS (
    SELECT DISTINCT "user_pseudo_id"
    FROM (
        SELECT "user_pseudo_id","event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180702"
        UNION ALL SELECT "user_pseudo_id","event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180703"
        UNION ALL SELECT "user_pseudo_id","event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180704"
        UNION ALL SELECT "user_pseudo_id","event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180705"
        UNION ALL SELECT "user_pseudo_id","event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180706"
        UNION ALL SELECT "user_pseudo_id","event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180707"
        UNION ALL SELECT "user_pseudo_id","event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180708"
    )
    WHERE "event_name" = 'session_start'
),

/* -------------------------------------------------- */
/* Week-1 : Mon 09-Jul-2018 – Sun 15-Jul-2018          */
week1 AS (
    SELECT DISTINCT "user_pseudo_id"
    FROM (
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180709"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180710"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180711"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180712"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180713"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180714"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180715"
    )
),

/* -------------------------------------------------- */
/* Week-2 : Mon 16-Jul-2018 – Sun 22-Jul-2018          */
week2 AS (
    SELECT DISTINCT "user_pseudo_id"
    FROM (
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180716"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180717"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180718"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180719"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180720"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180721"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180722"
    )
),

/* -------------------------------------------------- */
/* Week-3 : Mon 23-Jul-2018 – Sun 29-Jul-2018          */
week3 AS (
    SELECT DISTINCT "user_pseudo_id"
    FROM (
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180723"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180724"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180725"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180726"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180727"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180728"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180729"
    )
),

/* -------------------------------------------------- */
/* Week-4 : Mon 30-Jul-2018 – Sun 05-Aug-2018          */
week4 AS (
    SELECT DISTINCT "user_pseudo_id"
    FROM (
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180730"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180731"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180801"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180802"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180803"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180804"
        UNION ALL SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180805"
    )
)

/* -------------------------------------------------- */
SELECT
    /* cohort size */
    (SELECT COUNT(*) FROM week0)                                         AS "new_users_week0",
    /* retained users in subsequent weeks */
    (SELECT COUNT(*) FROM week0 JOIN week1 USING ("user_pseudo_id"))     AS "retained_week1",
    (SELECT COUNT(*) FROM week0 JOIN week2 USING ("user_pseudo_id"))     AS "retained_week2",
    (SELECT COUNT(*) FROM week0 JOIN week3 USING ("user_pseudo_id"))     AS "retained_week3",
    (SELECT COUNT(*) FROM week0 JOIN week4 USING ("user_pseudo_id"))     AS "retained_week4";