/*  Lowest 2-nd-week retention rate for any quick-play event whose first use
    occurred between 01-Aug-2018 and 15-Aug-2018                         */
WITH quickplay_events AS (          /* cohort-forming events (1–15 Aug) */
    SELECT "user_pseudo_id",
           "event_name",
           "event_date"
    FROM (
        SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801" UNION ALL
        SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802" UNION ALL
        SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803" UNION ALL
        SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804" UNION ALL
        SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805" UNION ALL
        SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806" UNION ALL
        SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807" UNION ALL
        SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808" UNION ALL
        SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809" UNION ALL
        SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810" UNION ALL
        SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811" UNION ALL
        SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812" UNION ALL
        SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813" UNION ALL
        SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814" UNION ALL
        SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815"
    )
    WHERE "event_name" ILIKE '%quickplay%'
),
cohort AS (                         /* first calendar day the user fired that event */
    SELECT "user_pseudo_id",
           "event_name",
           MIN(TO_DATE("event_date",'YYYYMMDD')) AS "first_date"
    FROM quickplay_events
    GROUP BY "user_pseudo_id","event_name"
),
session_starts AS (                 /* every session_start 01-Aug-2018–31-Aug-2018 */
    SELECT "user_pseudo_id",
           TO_DATE("event_date",'YYYYMMDD') AS "ss_date"
    FROM (
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180816" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180817" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180818" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180819" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180821" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180822" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180823" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180824" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180825" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180826" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180828" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180829" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180830" WHERE "event_name"='session_start' UNION ALL
        SELECT "user_pseudo_id","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180831" WHERE "event_name"='session_start'
    )
),
retention AS (                      /* cohort size & retained users */
    SELECT c."event_name",
           COUNT(*) AS "cohort_size",
           SUM(
               CASE
                   WHEN s."ss_date" BETWEEN c."first_date"+8 AND c."first_date"+14
                   THEN 1 ELSE 0
               END
           ) AS "retained_week2"
    FROM cohort            c
    LEFT JOIN session_starts s
           ON c."user_pseudo_id" = s."user_pseudo_id"
    GROUP BY c."event_name"
)
SELECT "event_name",
       "cohort_size",
       "retained_week2",
       "retained_week2"::FLOAT / "cohort_size" AS "week2_retention_rate"
FROM   retention
ORDER BY "week2_retention_rate" ASC NULLS LAST
LIMIT 1;