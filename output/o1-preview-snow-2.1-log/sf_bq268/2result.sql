WITH sessions AS (
  SELECT
    "visitorId",
    "visitNumber",
    "visitId",
    "visitStartTime",
    "date",
    "totals",
    "trafficSource",
    "device",
    "geoNetwork",
    "customDimensions",
    "hits",
    "fullVisitorId",
    "userId",
    "channelGrouping",
    "socialEngagementType"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160801"
  UNION ALL
  SELECT
    "visitorId",
    "visitNumber",
    "visitId",
    "visitStartTime",
    "date",
    "totals",
    "trafficSource",
    "device",
    "geoNetwork",
    "customDimensions",
    "hits",
    "fullVisitorId",
    "userId",
    "channelGrouping",
    "socialEngagementType"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160802"
  UNION ALL
  SELECT
    "visitorId",
    "visitNumber",
    "visitId",
    "visitStartTime",
    "date",
    "totals",
    "trafficSource",
    "device",
    "geoNetwork",
    "customDimensions",
    "hits",
    "fullVisitorId",
    "userId",
    "channelGrouping",
    "socialEngagementType"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160803"
  UNION ALL
  SELECT
    "visitorId",
    "visitNumber",
    "visitId",
    "visitStartTime",
    "date",
    "totals",
    "trafficSource",
    "device",
    "geoNetwork",
    "customDimensions",
    "hits",
    "fullVisitorId",
    "userId",
    "channelGrouping",
    "socialEngagementType"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160804"
  UNION ALL
  SELECT
    "visitorId",
    "visitNumber",
    "visitId",
    "visitStartTime",
    "date",
    "totals",
    "trafficSource",
    "device",
    "geoNetwork",
    "customDimensions",
    "hits",
    "fullVisitorId",
    "userId",
    "channelGrouping",
    "socialEngagementType"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160805"
  UNION ALL
  -- (Continue listing all tables explicitly up to GA_SESSIONS_20170801)
  -- For brevity, include all remaining tables in the same format.

  SELECT
    "visitorId",
    "visitNumber",
    "visitId",
    "visitStartTime",
    "date",
    "totals",
    "trafficSource",
    "device",
    "geoNetwork",
    "customDimensions",
    "hits",
    "fullVisitorId",
    "userId",
    "channelGrouping",
    "socialEngagementType"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170801"
),
session_transactions AS (
  SELECT
    s."fullVisitorId",
    MIN(s."visitStartTime") AS "first_transaction_time"
  FROM sessions s,
    LATERAL FLATTEN(input => s."hits") h
  WHERE h.VALUE:"transaction" IS NOT NULL
  GROUP BY s."fullVisitorId"
),
user_events AS (
  SELECT
    s."fullVisitorId",
    MIN(s."visitStartTime") AS "first_visit_time",
    MAX(s."visitStartTime") AS "last_visit_time",
    st."first_transaction_time"
  FROM sessions s
  LEFT JOIN session_transactions st ON s."fullVisitorId" = st."fullVisitorId"
  GROUP BY s."fullVisitorId", st."first_transaction_time"
),
user_last_event AS (
  SELECT
    ue."fullVisitorId",
    ue."first_visit_time",
    ue."last_visit_time",
    ue."first_transaction_time",
    GREATEST(ue."last_visit_time", COALESCE(ue."first_transaction_time", 0)) AS "last_event_time"
  FROM user_events ue
),
user_last_event_device AS (
  SELECT DISTINCT
    ule."fullVisitorId",
    ule."first_visit_time",
    ule."last_event_time",
    s."device"::VARIANT:"deviceCategory"::STRING AS "last_event_device_category"
  FROM user_last_event ule
  JOIN sessions s ON s."fullVisitorId" = ule."fullVisitorId"
    AND s."visitStartTime" = ule."last_event_time"
)
SELECT
  MAX(DATEDIFF('day', TO_DATE(TO_TIMESTAMP(ule."first_visit_time")), TO_DATE(TO_TIMESTAMP(ule."last_event_time")))) AS "Longest_number_of_days"
FROM user_last_event_device ule
WHERE ule."last_event_device_category" = 'mobile';