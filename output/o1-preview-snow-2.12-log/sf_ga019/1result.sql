WITH events AS
(
  SELECT "user_pseudo_id", "event_name", "event_timestamp"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180801"
  UNION ALL
  SELECT "user_pseudo_id", "event_name", "event_timestamp"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180802"
  UNION ALL
  -- Include all tables from EVENTS_20180803 to EVENTS_20180929
  SELECT "user_pseudo_id", "event_name", "event_timestamp"
  FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180930"
),
install_uninstall_times AS
(
  SELECT
    "user_pseudo_id",
    MIN(CASE WHEN "event_name" = 'first_open' THEN "event_timestamp" END) AS "install_time",
    MIN(CASE WHEN "event_name" = 'app_remove' THEN "event_timestamp" END) AS "uninstall_time"
  FROM events
  GROUP BY "user_pseudo_id"
)
SELECT
  ROUND(
    (COUNT(DISTINCT CASE WHEN "uninstall_time" IS NULL OR ("uninstall_time" - "install_time") / (1000*60*60*24) > 7 THEN "user_pseudo_id" END) * 100.0) /
    COUNT(DISTINCT "user_pseudo_id"), 4
  ) AS "Percentage_of_users"
FROM install_uninstall_times
WHERE "install_time" IS NOT NULL;