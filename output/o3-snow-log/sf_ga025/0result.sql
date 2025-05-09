/*--------------------------------------------------------------------
  % of users who first opened in Sept-2018, un-installed ≤7 days later,
  and experienced at least one crash (event_name = 'app_exception')
  -------------------------------------------------------------------*/
WITH union_events AS (

    /* --------  September 2018  -------- */
    SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930"

    /* --------  First 3 days of October 2018 (to capture 7-day window)  -------- */
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181003"
),

/* users whose very first touch was during September-2018 */
users AS (
    SELECT
        "user_pseudo_id"                                                     AS user_id,
        MIN( TO_DATE( TO_TIMESTAMP( "user_first_touch_timestamp" / 1000000 ) ) )
                                                                             AS first_touch_date
    FROM union_events
    GROUP BY user_id
    HAVING first_touch_date BETWEEN '2018-09-01' AND '2018-09-30'
),

/* earliest uninstall (app_remove) event per user */
uninstalls AS (
    SELECT
        "user_pseudo_id"                                                     AS user_id,
        MIN( TO_DATE( TO_TIMESTAMP( "event_timestamp" / 1000000 ) ) )        AS uninstall_date
    FROM union_events
    WHERE "event_name" = 'app_remove'
    GROUP BY user_id
),

/* users who experienced at least one crash (app_exception) within the first 7 days */
crashes AS (
    SELECT DISTINCT ue."user_pseudo_id"                                      AS user_id
    FROM union_events ue
    JOIN users u
      ON u.user_id = ue."user_pseudo_id"
    WHERE ue."event_name" = 'app_exception'
      AND TO_DATE( TO_TIMESTAMP( ue."event_timestamp" / 1000000 ) )
          BETWEEN u.first_touch_date AND (u.first_touch_date + 7)
),

/* users who uninstalled ≤7 days after first touch */
qualified_users AS (
    SELECT
        u.user_id,
        CASE WHEN c.user_id IS NOT NULL THEN 1 ELSE 0 END                    AS had_crash
    FROM users        u
    JOIN uninstalls   un ON u.user_id = un.user_id
    LEFT JOIN crashes c  ON u.user_id = c.user_id
    WHERE DATEDIFF( 'day', u.first_touch_date, un.uninstall_date ) <= 7
),

/* aggregate counts */
agg AS (
    SELECT
        COUNT(*)                                AS total_uninstalls_7d,
        SUM(had_crash)                          AS crash_uninstalls_7d
    FROM qualified_users
)

SELECT
    CASE
        WHEN total_uninstalls_7d = 0 THEN 0
        ELSE ROUND( crash_uninstalls_7d * 100.0 / total_uninstalls_7d , 4)
    END                                         AS "PERCENTAGE_WITH_CRASH_BEFORE_7D_UNINSTALL"
FROM agg;