/* -----------------------------------------------------------
   % of September-2018 new users (first_open) who uninstalled
   within 7 days and, at any time before uninstall, generated
   at least one crash event (app_exception)
   ----------------------------------------------------------- */
WITH events_all AS (      ---------------------------------------------------
    /* gather only the columns required from every available
       daily table between 2018-09-01 and 2018-10-03            */
    SELECT "user_pseudo_id",
           "event_name",
           "event_timestamp",
           "user_first_touch_timestamp"
    FROM (
        SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002"
        UNION ALL SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181003"
    )
),
/* first open date for every user                                    */
first_open_users AS (
    SELECT
        "user_pseudo_id",
        DATE( TO_TIMESTAMP_LTZ( "user_first_touch_timestamp" / 1000000 ) ) AS first_open_date
    FROM events_all
    GROUP BY "user_pseudo_id","user_first_touch_timestamp"
    HAVING first_open_date BETWEEN '2018-09-01' AND '2018-09-30'
),
/* earliest uninstall (app_remove) date per user                      */
uninstall_dates AS (
    SELECT
        "user_pseudo_id",
        MIN( DATE( TO_TIMESTAMP_LTZ( "event_timestamp" / 1000000 ) ) ) AS uninstall_date
    FROM events_all
    WHERE "event_name" = 'app_remove'
    GROUP BY "user_pseudo_id"
),
/* users who uninstalled within 7 days of first open                  */
denominator_users AS (
    SELECT
        f."user_pseudo_id",
        f.first_open_date,
        u.uninstall_date
    FROM first_open_users  f
    JOIN uninstall_dates  u
          ON f."user_pseudo_id" = u."user_pseudo_id"
    WHERE DATEDIFF('day', f.first_open_date, u.uninstall_date) BETWEEN 0 AND 7
),
/* users who generated at least one crash event                       */
crash_users AS (
    SELECT DISTINCT "user_pseudo_id"
    FROM events_all
    WHERE "event_name" = 'app_exception'
),
/* users who meet both conditions                                     */
numerator_users AS (
    SELECT d."user_pseudo_id"
    FROM   denominator_users d
    JOIN   crash_users       c USING ("user_pseudo_id")
)
/* ------------------------------------------------------------------ */
SELECT
    COUNT(DISTINCT n."user_pseudo_id")                     AS users_with_crash ,
    COUNT(DISTINCT d."user_pseudo_id")                     AS total_uninstalls_within_7d ,
    ROUND( 100.0 * COUNT(DISTINCT n."user_pseudo_id")
                 / NULLIF( COUNT(DISTINCT d."user_pseudo_id") , 0 )
          , 4 )                                            AS percentage_crashed
FROM denominator_users d
LEFT JOIN numerator_users n
       ON d."user_pseudo_id" = n."user_pseudo_id";