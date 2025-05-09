WITH "EVENTS" AS (   /* --------  ALL SEPT-18  & EARLY OCT-18 DAILY TABLES  -------- */
    SELECT "user_pseudo_id",
           "user_first_touch_timestamp",
           "event_name",
           "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901"  UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002" UNION ALL
    SELECT "user_pseudo_id","user_first_touch_timestamp","event_name","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181003"
),  /* ------------  USERS WHO FIRST OPENED IN SEPT-18  ------------ */
"SEPT_USERS" AS (
    SELECT DISTINCT
           "user_pseudo_id"                          AS "user_id",
           TO_DATE(TO_TIMESTAMP("user_first_touch_timestamp"/1000000)) 
                                                     AS "first_touch_date"
    FROM "EVENTS"
    WHERE TO_DATE(TO_TIMESTAMP("user_first_touch_timestamp"/1000000))
          BETWEEN '2018-09-01' AND '2018-09-30'
),  /* ------------  UNINSTALL DATE (app_remove)  ------------ */
"UNINSTALLS" AS (
    SELECT
        "user_pseudo_id"                             AS "user_id",
        MIN(TO_DATE(TO_TIMESTAMP("event_timestamp"/1000000))) 
                                                     AS "uninstall_date"
    FROM "EVENTS"
    WHERE "event_name" = 'app_remove'
      AND "user_pseudo_id" IN (SELECT "user_id" FROM "SEPT_USERS")
    GROUP BY "user_pseudo_id"
),  /* ------------  QUALIFIED USERS (UNINSTALLED ≤ 7 DAYS)  ------------ */
"QUALIFIED" AS (
    SELECT
        s."user_id",
        s."first_touch_date",
        u."uninstall_date",
        DATEDIFF('day', s."first_touch_date", u."uninstall_date") 
                                                     AS "days_to_uninstall"
    FROM "SEPT_USERS"  s
    JOIN "UNINSTALLS" u ON u."user_id" = s."user_id"
    WHERE DATEDIFF('day', s."first_touch_date", u."uninstall_date") <= 7
),  /* ------------  CRASHES WITHIN THE SAME 7-DAY WINDOW  ------------ */
"CRASH_USERS" AS (
    SELECT DISTINCT
           e."user_pseudo_id"                        AS "user_id"
    FROM "EVENTS" e
    JOIN "QUALIFIED" q
      ON q."user_id" = e."user_pseudo_id"
    WHERE e."event_name" = 'app_exception'
      AND TO_DATE(TO_TIMESTAMP(e."event_timestamp"/1000000))
          BETWEEN q."first_touch_date"
              AND DATEADD('day', 7, q."first_touch_date")
)
/* ------------  FINAL PERCENTAGE  ------------ */
SELECT
    ROUND( 100 * COUNT(c."user_id") / NULLIF(COUNT(q."user_id"),0), 4)
        AS "percent_users_uninstalling_within_7d_who_crashed"
FROM "QUALIFIED" q
LEFT JOIN "CRASH_USERS" c
       ON c."user_id" = q."user_id";