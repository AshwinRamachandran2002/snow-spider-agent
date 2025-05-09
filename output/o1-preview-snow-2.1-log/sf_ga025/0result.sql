WITH FirstOpenUsers AS (
  SELECT "user_pseudo_id", MIN("event_timestamp") AS "first_open_time"
  FROM (
    SELECT "user_pseudo_id", "event_timestamp", "event_name"
    FROM (
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930"
    ) AS all_events
    WHERE "event_name" = 'first_open'
  ) fe
  GROUP BY "user_pseudo_id"
),
UninstallsWithin7Days AS (
  SELECT fe."user_pseudo_id", MIN(ue."event_timestamp") AS "uninstall_time"
  FROM FirstOpenUsers fe
  JOIN (
    SELECT "user_pseudo_id", "event_timestamp", "event_name"
    FROM (
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181003"
    ) AS all_uninstalls
    WHERE "event_name" = 'app_remove'
  ) ue ON fe."user_pseudo_id" = ue."user_pseudo_id"
  WHERE ue."event_timestamp" <= fe."first_open_time" + 7*24*60*60*1000000
  GROUP BY fe."user_pseudo_id"
),
CrashEvents AS (
  SELECT DISTINCT fe."user_pseudo_id"
  FROM FirstOpenUsers fe
  JOIN UninstallsWithin7Days uw7d ON fe."user_pseudo_id" = uw7d."user_pseudo_id"
  JOIN (
    SELECT "user_pseudo_id", "event_timestamp", "event_name"
    FROM (
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002"
      UNION ALL
      SELECT "user_pseudo_id", "event_timestamp", "event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181003"
    ) AS all_crash_events
    WHERE "event_name" IN ('app_exception', 'error')
  ) ce ON fe."user_pseudo_id" = ce."user_pseudo_id"
  WHERE ce."event_timestamp" BETWEEN fe."first_open_time" AND uw7d."uninstall_time"
)
SELECT
  ROUND((COUNT(DISTINCT "user_pseudo_id") * 100.0) / (SELECT COUNT(DISTINCT "user_pseudo_id") FROM UninstallsWithin7Days), 4) AS "Percentage_of_users_who_experienced_crash"
FROM CrashEvents;