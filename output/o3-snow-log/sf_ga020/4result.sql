WITH quickplay_source AS (      -- every quick-play event logged 01-Aug-2018  ➜ 15-Aug-2018
    SELECT "user_pseudo_id","event_name","event_timestamp"
    FROM (
            SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801"
            UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802"
            UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803"
            UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804"
            UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805"
            UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806"
            UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807"
            UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808"
            UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809"
            UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810"
            UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811"
            UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812"
            UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813"
            UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814"
            UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815"
         )
    WHERE "event_name" ILIKE '%quickplay%'
),
cohort AS (                     -- first quick-play event per user (= cohort entry)
    SELECT
        "user_pseudo_id",
        MIN_BY("event_name","event_timestamp") AS "first_event",
        MIN("event_timestamp")                 AS "first_ts"
    FROM quickplay_source
    GROUP BY "user_pseudo_id"
),
session_source AS (             -- every session_start logged 08-Aug-2018  ➜ 29-Aug-2018
    SELECT "user_pseudo_id","event_timestamp"
    FROM (
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808"
            UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809"
            UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810"
            UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811"
            UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812"
            UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813"
            UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814"
            UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815"
            UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180816"
            UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180817"
            UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180818"
            UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180819"
            UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820"
            UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180821"
            UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180822"
            UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180823"
            UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180824"
            UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180825"
            UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180826"
            UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827"
            UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180828"
            UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180829"
         )
    WHERE "event_name" = 'session_start'
),
retained AS (                   -- users with a session 8-14 days after first quick-play
    SELECT DISTINCT s."user_pseudo_id"
    FROM cohort c
    JOIN session_source s
      ON s."user_pseudo_id" = c."user_pseudo_id"
     AND s."event_timestamp" >= c."first_ts" + 7*24*60*60*1000000
     AND s."event_timestamp" <  c."first_ts" +14*24*60*60*1000000
),
rates AS (                      -- retention rate per quick-play entry type
    SELECT
        c."first_event"                    AS "quickplay_event_type",
        COUNT(DISTINCT c."user_pseudo_id") AS cohort_users,
        COUNT(DISTINCT r."user_pseudo_id") AS retained_users,
        COUNT(DISTINCT r."user_pseudo_id")::FLOAT
          / NULLIF(COUNT(DISTINCT c."user_pseudo_id"),0) AS retention_rate
    FROM cohort c
    LEFT JOIN retained r ON c."user_pseudo_id" = r."user_pseudo_id"
    GROUP BY c."first_event"
)
SELECT "quickplay_event_type" AS "quickplay_event_type_with_lowest_retention"
FROM rates
ORDER BY retention_rate
LIMIT 1;