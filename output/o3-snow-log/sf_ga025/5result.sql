/*  PERCENTAGE OF SEPT-2018 FIRST-OPEN USERS WHO UNINSTALLED WITHIN 7 DAYS
    AND ALSO EXPERIENCED AN APP CRASH (event_name = 'app_exception')          */

WITH all_events AS (          -- bring together every needed daily table
    SELECT  "user_pseudo_id",
            "event_name",
            "event_date",                 -- text YYYYMMDD
            "user_first_touch_timestamp"  -- micro-seconds
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901"  UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902"  UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903"  UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904"  UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905"  UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906"  UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907"  UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908"  UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909"  UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002" UNION ALL
    SELECT "user_pseudo_id","event_name","event_date","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181003"
),

first_open AS (   -- users whose first touch is in September-2018
    SELECT  "user_pseudo_id",
            TO_DATE( TO_TIMESTAMP_LTZ( MIN("user_first_touch_timestamp"), 6) )   AS first_open_date
    FROM    all_events
    GROUP BY "user_pseudo_id"
    HAVING  first_open_date BETWEEN '2018-09-01' AND '2018-09-30'
),

uninstall_events AS (  -- first uninstall (app_remove) date per user
    SELECT  "user_pseudo_id",
            MIN( TO_DATE("event_date", 'YYYYMMDD') )  AS uninstall_date
    FROM    all_events
    WHERE   "event_name" = 'app_remove'
    GROUP BY "user_pseudo_id"
),

uninstall_within_7 AS (   -- keep only those who uninstalled within 7 days
    SELECT  fo."user_pseudo_id",
            fo.first_open_date,
            ue.uninstall_date
    FROM    first_open        fo
    JOIN    uninstall_events  ue
           ON fo."user_pseudo_id" = ue."user_pseudo_id"
    WHERE   DATEDIFF('day', fo.first_open_date, ue.uninstall_date) BETWEEN 0 AND 7
),

crash_users AS (           -- users with any app_exception
    SELECT DISTINCT "user_pseudo_id"
    FROM   all_events
    WHERE  "event_name" = 'app_exception'
)

SELECT  
    ROUND( COUNT(DISTINCT CASE WHEN cu."user_pseudo_id" IS NOT NULL 
                               THEN uw."user_pseudo_id" END) 
           * 100.0 
           / COUNT(DISTINCT uw."user_pseudo_id"), 4
    )  AS "PERCENT_OF_UNINSTALLED_USERS_WITH_CRASH"
FROM    uninstall_within_7  uw
LEFT JOIN crash_users       cu
       ON uw."user_pseudo_id" = cu."user_pseudo_id";