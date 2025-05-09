/*------------------------------------------------------------
   Lowest week-2 retention (session_start) by first QUICKPLAY
   event for users whose very first quick-play happened between
   01-Aug-2018 and 15-Aug-2018 (inclusive).
------------------------------------------------------------*/
WITH quickplay_events AS (          -- all events 1-15 Aug
    SELECT "user_pseudo_id",
           "event_timestamp",
           "event_name"
    FROM (  SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815"
    )
    WHERE "event_name" ILIKE '%quickplay%'
),
first_quickplay AS (                -- one row per user
    SELECT  "user_pseudo_id",
            MIN("event_timestamp")          AS first_ts
    FROM quickplay_events
    GROUP BY "user_pseudo_id"
),
first_quickplay_labeled AS (        -- attach the event name
    SELECT  f."user_pseudo_id",
            f.first_ts,
            e."event_name"          AS first_quickplay_event
    FROM first_quickplay f
    JOIN quickplay_events e
      ON  f."user_pseudo_id" = e."user_pseudo_id"
      AND f.first_ts         = e."event_timestamp"
),
session_starts AS (                 -- all session_start 8-29 Aug
    SELECT "user_pseudo_id",
           "event_timestamp"
    FROM (  SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180816" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180817" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180818" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180819" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180821" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180822" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180823" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180824" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180825" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180826" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180828" UNION ALL
            SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180829"
    )
    WHERE "event_name" = 'session_start'
),
week2_retained AS (                 -- users with session_start 8-14 days later
    SELECT DISTINCT f."user_pseudo_id"
    FROM first_quickplay_labeled f
    JOIN session_starts s
      ON  f."user_pseudo_id" = s."user_pseudo_id"
      AND s."event_timestamp"
          BETWEEN f.first_ts + 7 * 24 * 60 * 60 * 1000000      -- +7 days
          AND     f.first_ts +14 * 24 * 60 * 60 * 1000000      -- +14 days
),
retention_summary AS (
    SELECT  f.first_quickplay_event,
            COUNT(DISTINCT f."user_pseudo_id")        AS users_total,
            COUNT(DISTINCT r."user_pseudo_id")        AS users_retained_wk2,
            ROUND( COUNT(DISTINCT r."user_pseudo_id") :: FLOAT
                  / NULLIF( COUNT(DISTINCT f."user_pseudo_id"),0)
                 ,4)                                  AS wk2_retention_rate
    FROM first_quickplay_labeled f
    LEFT JOIN week2_retained r
           ON f."user_pseudo_id" = r."user_pseudo_id"
    GROUP BY first_quickplay_event
)
SELECT *
FROM   retention_summary
ORDER  BY wk2_retention_rate ASC NULLS LAST
LIMIT  1;