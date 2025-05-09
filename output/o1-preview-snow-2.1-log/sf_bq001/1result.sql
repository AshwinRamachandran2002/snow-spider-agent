WITH sessions AS (
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER AS "transactions",
    "device":"deviceCategory"::STRING AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170201"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER  AS "transactions",
    "device":"deviceCategory"::STRING  AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170202"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER  AS "transactions",
    "device":"deviceCategory"::STRING  AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170203"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER  AS "transactions",
    "device":"deviceCategory"::STRING  AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170204"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER  AS "transactions",
    "device":"deviceCategory"::STRING  AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170205"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER  AS "transactions",
    "device":"deviceCategory"::STRING  AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170206"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER  AS "transactions",
    "device":"deviceCategory"::STRING  AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170207"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER  AS "transactions",
    "device":"deviceCategory"::STRING  AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170208"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER  AS "transactions",
    "device":"deviceCategory"::STRING  AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170209"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER  AS "transactions",
    "device":"deviceCategory"::STRING  AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170210"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER  AS "transactions",
    "device":"deviceCategory"::STRING  AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170211"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER  AS "transactions",
    "device":"deviceCategory"::STRING  AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170212"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER AS "transactions",
    "device":"deviceCategory"::STRING AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170213"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER AS "transactions",
    "device":"deviceCategory"::STRING AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170214"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER AS "transactions",
    "device":"deviceCategory"::STRING AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170215"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER AS "transactions",
    "device":"deviceCategory"::STRING AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170216"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER AS "transactions",
    "device":"deviceCategory"::STRING AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170217"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER AS "transactions",
    "device":"deviceCategory"::STRING AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170218"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER AS "transactions",
    "device":"deviceCategory"::STRING AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170219"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER AS "transactions",
    "device":"deviceCategory"::STRING AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170220"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER AS "transactions",
    "device":"deviceCategory"::STRING AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170221"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER AS "transactions",
    "device":"deviceCategory"::STRING AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170222"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER AS "transactions",
    "device":"deviceCategory"::STRING AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170223"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER AS "transactions",
    "device":"deviceCategory"::STRING AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170224"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER AS "transactions",
    "device":"deviceCategory"::STRING AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170225"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER AS "transactions",
    "device":"deviceCategory"::STRING AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170226"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER AS "transactions",
    "device":"deviceCategory"::STRING AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170227"
  UNION ALL
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "visit_date",
    "totals":"transactions"::INTEGER AS "transactions",
    "device":"deviceCategory"::STRING AS "deviceCategory"
  FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170228"
),
first_visits AS (
  SELECT
    "fullVisitorId",
    MIN("visit_date") AS "first_visit_date"
  FROM sessions
  GROUP BY "fullVisitorId"
),
first_transactions AS (
  SELECT
    "fullVisitorId",
    "first_transaction_date",
    "deviceCategory"
  FROM (
    SELECT
      "fullVisitorId",
      "visit_date" AS "first_transaction_date",
      "deviceCategory",
      ROW_NUMBER() OVER (PARTITION BY "fullVisitorId" ORDER BY "visit_date") AS rn
    FROM sessions
    WHERE "transactions" > 0
  )
  WHERE rn = 1
)
SELECT
  t."fullVisitorId",
  DATEDIFF('day', v."first_visit_date", t."first_transaction_date") AS "days_between",
  t."deviceCategory"
FROM
  first_transactions t
JOIN
  first_visits v ON t."fullVisitorId" = v."fullVisitorId"
ORDER BY
  t."fullVisitorId";