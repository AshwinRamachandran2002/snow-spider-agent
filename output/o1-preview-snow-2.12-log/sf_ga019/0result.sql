WITH events AS (
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180804"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180808"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180809"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180815"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180816"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180817"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180818"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180820"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180826"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180827"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180830"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180901"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180904"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180905"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180906"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180907"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180908"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180910"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180915"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180916"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180917"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180918"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180922"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180924"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180928"
  UNION ALL
  SELECT "user_pseudo_id", "event_timestamp", "event_date", "event_name"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180929"
),

install_events AS (
  SELECT "user_pseudo_id", MIN("event_timestamp") AS "install_timestamp"
  FROM events
  WHERE "event_name" = 'first_open'
    AND "event_date" BETWEEN '20180801' AND '20180930'
  GROUP BY "user_pseudo_id"
),

uninstall_events AS (
  SELECT "user_pseudo_id", MIN("event_timestamp") AS "uninstall_timestamp"
  FROM events
  WHERE "event_name" = 'app_remove'
  GROUP BY "user_pseudo_id"
),

joined_events AS (
  SELECT i."user_pseudo_id",
         i."install_timestamp",
         u."uninstall_timestamp",
         DATEDIFF(
           'day',
           TO_TIMESTAMP_NTZ(i."install_timestamp" / 1000000),
           TO_TIMESTAMP_NTZ(u."uninstall_timestamp" / 1000000)
         ) AS days_until_uninstall
  FROM install_events i
  LEFT JOIN uninstall_events u
    ON i."user_pseudo_id" = u."user_pseudo_id"
      AND u."uninstall_timestamp" >= i."install_timestamp"
)

SELECT ROUND(
  (COUNT(CASE WHEN (days_until_uninstall > 7 OR days_until_uninstall IS NULL) THEN 1 END)
  / COUNT(*)) * 100.0, 4) AS "Percentage_of_users"
FROM joined_events;