WITH initial_events AS (
  SELECT
    t."user_pseudo_id",
    MIN(t."event_timestamp") AS "initial_timestamp",
    f.value:"value":"string_value"::STRING AS "board_value"
  FROM (
    SELECT "user_pseudo_id", "event_timestamp", "event_params", "event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180702"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp", "event_params", "event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180703"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp", "event_params", "event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180704"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp", "event_params", "event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180705"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp", "event_params", "event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180706"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp", "event_params", "event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180707"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp", "event_params", "event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180708"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp", "event_params", "event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180709"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp", "event_params", "event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180710"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp", "event_params", "event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180711"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp", "event_params", "event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180712"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp", "event_params", "event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180713"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp", "event_params", "event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180714"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp", "event_params", "event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180715"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp", "event_params", "event_name" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180716"
  ) t,
  LATERAL FLATTEN(input => t."event_params") f
  WHERE t."event_name" LIKE '%quickplay%'
    AND f.value:"key"::STRING = 'board'
    AND f.value:"value":"string_value"::STRING IN ('S', 'M', 'L')
  GROUP BY t."user_pseudo_id", f.value:"value":"string_value"::STRING
),
return_events AS (
  SELECT t."user_pseudo_id", t."event_timestamp" AS "return_timestamp"
  FROM (
    SELECT "user_pseudo_id", "event_timestamp" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180716"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180717"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180718"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180719"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180720"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180721"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180722"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180723"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180724"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180725"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180726"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180727"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180728"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180729"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180730"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180731"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180801"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180802"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180803"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180804"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180805"
  ) t
),
user_retention AS (
  SELECT
    initial_events."user_pseudo_id",
    initial_events."board_value",
    initial_events."initial_timestamp",
    MIN(return_events."return_timestamp") AS "return_timestamp"
  FROM initial_events
  LEFT JOIN return_events
    ON initial_events."user_pseudo_id" = return_events."user_pseudo_id"
    AND return_events."return_timestamp" >= initial_events."initial_timestamp" + 1209600000000
    AND return_events."return_timestamp" < initial_events."initial_timestamp" + 1728000000000
  GROUP BY initial_events."user_pseudo_id", initial_events."board_value", initial_events."initial_timestamp"
),
retention_rates AS (
  SELECT
    "board_value",
    COUNT(DISTINCT "user_pseudo_id") AS "total_users",
    COUNT(DISTINCT CASE WHEN "return_timestamp" IS NOT NULL THEN "user_pseudo_id" END) AS "users_returned"
  FROM user_retention
  GROUP BY "board_value"
)
SELECT
  "board_value" AS "Quickplay_Event_Type",
  ROUND(("users_returned"::FLOAT / "total_users") * 100, 4) AS "Retention_Rate"
FROM retention_rates;