WITH all_sessions AS (
  SELECT "fullVisitorId", "visitStartTime", "device", "totals"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160801"
  UNION ALL
  SELECT "fullVisitorId", "visitStartTime", "device", "totals"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160802"
  UNION ALL
  SELECT "fullVisitorId", "visitStartTime", "device", "totals"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160803"
  UNION ALL
  SELECT "fullVisitorId", "visitStartTime", "device", "totals"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160804"
  UNION ALL
  SELECT "fullVisitorId", "visitStartTime", "device", "totals"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160805"
  UNION ALL
  -- (Continue listing all GA_SESSIONS_* tables up to "GA_SESSIONS_20170801")
  SELECT "fullVisitorId", "visitStartTime", "device", "totals"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170801"
),
all_visits AS (
  SELECT
    "fullVisitorId",
    TO_DATE(TO_TIMESTAMP("visitStartTime")) AS "visitDate",
    "device"['deviceCategory']::STRING AS "deviceCategory",
    "totals"['transactions']::NUMBER AS "transactions"
  FROM all_sessions
),
first_visits AS (
  SELECT
    "fullVisitorId",
    MIN("visitDate") AS "firstVisitDate"
  FROM all_visits
  GROUP BY "fullVisitorId"
),
first_transactions AS (
  SELECT
    "fullVisitorId",
    MIN("visitDate") AS "firstTransactionDate"
  FROM all_visits
  WHERE "transactions" > 0 AND "deviceCategory" = 'mobile'
  GROUP BY "fullVisitorId"
)
SELECT DISTINCT ft."fullVisitorId" AS "visitorId"
FROM first_visits fv
JOIN first_transactions ft ON fv."fullVisitorId" = ft."fullVisitorId"
WHERE ft."firstTransactionDate" <> fv."firstVisitDate";