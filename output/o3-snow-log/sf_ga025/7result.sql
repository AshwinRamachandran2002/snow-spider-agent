/*----------------------------------------------------------
  Percentage of September-2018 new users who un-installed
  within seven days AND experienced an app crash inside
  that same seven-day window.
-----------------------------------------------------------*/
WITH union_events AS (          -- 1. Union ALL required days
    SELECT  "user_pseudo_id"                AS USER_ID,
            "event_name"                    AS EVENT_NAME,
            "event_timestamp"               AS EVENT_TIMESTAMP,
            "user_first_touch_timestamp"    AS USER_FIRST_TOUCH_TIMESTAMP
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002"
    UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181003"
),

/*----------------------------------------------------------
  2.  Users whose very first touch is in September 2018
-----------------------------------------------------------*/
first_open_users AS (
    SELECT  USER_ID,
            MIN( TO_DATE( TO_TIMESTAMP_LTZ( USER_FIRST_TOUCH_TIMESTAMP / 1000000 ) ) ) AS FIRST_OPEN_DATE
    FROM    union_events
    GROUP BY USER_ID
    HAVING  FIRST_OPEN_DATE BETWEEN '2018-09-01' AND '2018-09-30'
),

/*----------------------------------------------------------
  3.  Events that belong only to the users above
-----------------------------------------------------------*/
events_for_these_users AS (
    SELECT  e.USER_ID,
            e.EVENT_NAME,
            TO_DATE( TO_TIMESTAMP_LTZ( e.EVENT_TIMESTAMP / 1000000 ) ) AS EVENT_DATE,
            f.FIRST_OPEN_DATE
    FROM    union_events        e
    JOIN    first_open_users    f ON e.USER_ID = f.USER_ID
),

/*----------------------------------------------------------
  4.  First uninstall (app_remove) date of each user
-----------------------------------------------------------*/
uninstall_dates AS (
    SELECT  USER_ID,
            MIN(EVENT_DATE) AS UNINSTALL_DATE
    FROM    events_for_these_users
    WHERE   EVENT_NAME = 'app_remove'
    GROUP BY USER_ID
),

/*----------------------------------------------------------
  5.  First crash (app_exception) date of each user
-----------------------------------------------------------*/
crash_dates AS (
    SELECT  USER_ID,
            MIN(EVENT_DATE) AS CRASH_DATE
    FROM    events_for_these_users
    WHERE   EVENT_NAME = 'app_exception'
    GROUP BY USER_ID
),

/*----------------------------------------------------------
  6.  Users who uninstalled within 7 days of first open
-----------------------------------------------------------*/
qualified_users AS (
    SELECT  f.USER_ID,
            f.FIRST_OPEN_DATE,
            u.UNINSTALL_DATE,
            DATEDIFF(day, f.FIRST_OPEN_DATE, u.UNINSTALL_DATE) AS DAYS_TO_UNINSTALL
    FROM    first_open_users  f
    JOIN    uninstall_dates   u ON f.USER_ID = u.USER_ID
    WHERE   DATEDIFF(day, f.FIRST_OPEN_DATE, u.UNINSTALL_DATE) <= 7
),

/*----------------------------------------------------------
  7.  Qualified users who also crashed within that window
-----------------------------------------------------------*/
crash_users AS (
    SELECT  q.USER_ID
    FROM    qualified_users q
    JOIN    crash_dates     c
           ON q.USER_ID = c.USER_ID
          AND c.CRASH_DATE BETWEEN q.FIRST_OPEN_DATE AND q.UNINSTALL_DATE
)

/*----------------------------------------------------------
  8.  Final percentage
-----------------------------------------------------------*/
SELECT
    ROUND(
          ( SELECT COUNT(*) FROM crash_users      ) * 100.0
        / NULLIF( ( SELECT COUNT(*) FROM qualified_users ), 0 )
    , 4) AS "PERCENT_CRASHED_WITHIN_7_DAYS";