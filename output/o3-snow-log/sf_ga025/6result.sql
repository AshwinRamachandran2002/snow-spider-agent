/*--------------------------------------------------------------------
   % of September-2018 first-open users who un-installed ≤7 days later
   and also generated at least one crash event (event_name = app_exception)
--------------------------------------------------------------------*/
WITH union_events AS (

    /* ---------------   2018-09   --------------- */
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930" UNION ALL

    /* ---------------   2018-10 (needed for ≤7-day uninstall window)   --------------- */
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp","user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181003"
),

/* first open date (based on user_first_touch_timestamp) -------------------------- */
first_open AS (
  SELECT
      "user_pseudo_id"                                              AS user_id,
      MIN( TO_DATE( TO_TIMESTAMP( "user_first_touch_timestamp"/1000000 ) ) )
           AS first_open_date
  FROM union_events
  GROUP BY "user_pseudo_id"
  HAVING first_open_date BETWEEN '2018-09-01' AND '2018-09-30'
),

/* uninstall (app_remove) date ---------------------------------------------------- */
uninstalls AS (
  SELECT
      "user_pseudo_id"                                              AS user_id,
      MIN( TO_DATE( TO_TIMESTAMP( "event_timestamp"/1000000 ) ) )    AS uninstall_date
  FROM union_events
  WHERE "event_name" = 'app_remove'
  GROUP BY "user_pseudo_id"
),

/* users who ever had a crash (app_exception) ------------------------------------ */
crashes AS (
  SELECT DISTINCT "user_pseudo_id" AS user_id
  FROM union_events
  WHERE "event_name" = 'app_exception'
),

/* bring everything together & keep only ≤7-day uninstalls ----------------------- */
qualified_users AS (
  SELECT
      f.user_id,
      f.first_open_date,
      u.uninstall_date,
      CASE WHEN c.user_id IS NOT NULL THEN 1 ELSE 0 END AS had_crash
  FROM first_open   f
  JOIN uninstalls   u ON f.user_id = u.user_id
  LEFT JOIN crashes c ON f.user_id = c.user_id
  WHERE DATEDIFF('day', f.first_open_date, u.uninstall_date) <= 7
)

/* final percentage -------------------------------------------------------------- */
SELECT
    ROUND( SUM(had_crash)::FLOAT / COUNT(*) * 100 , 4 )   AS PCT_UNINSTALLS_WITH_CRASH
FROM qualified_users;