/* -------------------------------------------------------------------------
   Percentage of September-2018 first-open users who un-installed within
   7 days and experienced at least one crash before the uninstall.
---------------------------------------------------------------------------*/
WITH events AS (   ----------------------------------------------------------
    SELECT "user_pseudo_id",
           "event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0)) AS event_date
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002" UNION ALL
    SELECT "user_pseudo_id","event_name",
           TO_DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1000000.0))
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181003"
),  -------------------------------------------------------------------------
first_open AS (
    SELECT "user_pseudo_id",
           MIN(event_date) AS first_open_date
    FROM   events
    WHERE  "event_name" = 'first_open'
      AND  event_date BETWEEN '2018-09-01' AND '2018-09-30'
    GROUP BY "user_pseudo_id"
),
uninstall AS (
    SELECT f."user_pseudo_id",
           MIN(e.event_date) AS uninstall_date
    FROM   events  e
    JOIN   first_open f
      ON   f."user_pseudo_id" = e."user_pseudo_id"
    WHERE  e."event_name" = 'app_remove'
      AND  DATEDIFF('day', f.first_open_date, e.event_date) BETWEEN 0 AND 7
    GROUP BY f."user_pseudo_id"
),
crashes AS (
    SELECT DISTINCT f."user_pseudo_id"
    FROM   events  e
    JOIN   first_open f ON f."user_pseudo_id" = e."user_pseudo_id"
    JOIN   uninstall  u ON u."user_pseudo_id" = e."user_pseudo_id"
    WHERE  e."event_name" = 'app_exception'
      AND  e.event_date BETWEEN f.first_open_date AND u.uninstall_date
)
SELECT  COUNT(DISTINCT u."user_pseudo_id") AS "TOTAL_USERS_UNINSTALL_WITHIN_7_DAYS",
        COUNT(DISTINCT c."user_pseudo_id") AS "USERS_WITH_CRASH",
        ROUND(
            (COUNT(DISTINCT c."user_pseudo_id") * 100.0) /
            NULLIF(COUNT(DISTINCT u."user_pseudo_id"), 0),
            4
        )                                   AS "PERCENTAGE_WITH_CRASH"
FROM    uninstall u
LEFT JOIN crashes c
       ON u."user_pseudo_id" = c."user_pseudo_id";