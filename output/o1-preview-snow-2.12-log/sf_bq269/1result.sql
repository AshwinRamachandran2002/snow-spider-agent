WITH all_sessions AS (
  SELECT "fullVisitorId", "date", "totals" FROM (
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170601"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170602"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170603"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170604"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170605"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170606"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170607"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170608"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170609"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170610"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170611"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170612"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170613"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170614"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170615"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170616"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170617"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170618"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170619"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170620"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170621"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170622"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170623"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170624"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170625"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170626"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170627"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170628"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170629"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170630"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170701"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170702"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170703"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170704"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170705"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170706"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170707"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170708"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170709"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170710"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170711"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170712"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170713"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170714"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170715"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170716"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170717"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170718"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170719"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170720"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170721"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170722"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170723"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170724"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170725"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170726"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170727"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170728"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170729"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170730"
    UNION ALL
    SELECT "fullVisitorId", "date", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170731"
  )
  WHERE "date" BETWEEN '20170601' AND '20170731'
),
session_data AS (
  SELECT
    "fullVisitorId",
    TO_DATE("date", 'YYYYMMDD') AS "session_date",
    CASE
      WHEN TRY_TO_NUMBER("totals":"transactions"::STRING) >= 1 THEN 'purchase'
      ELSE 'non_purchase'
    END AS "session_type",
    TRY_TO_NUMBER("totals":"pageviews"::STRING) AS "pageviews"
  FROM all_sessions
  WHERE "totals":"pageviews" IS NOT NULL
),
visitor_monthly_pageviews AS (
  SELECT
    "fullVisitorId",
    "session_type",
    TO_CHAR("session_date", 'MMMM YYYY') AS "Month",
    SUM("pageviews") AS total_pageviews
  FROM session_data
  GROUP BY "fullVisitorId", "session_type", "Month"
)
SELECT
  "Month",
  ROUND(AVG(CASE WHEN "session_type" = 'purchase' THEN total_pageviews END), 4) AS "Average_Pageviews_Purchase",
  ROUND(AVG(CASE WHEN "session_type" = 'non_purchase' THEN total_pageviews END), 4) AS "Average_Pageviews_Non_Purchase"
FROM visitor_monthly_pageviews
GROUP BY "Month"
ORDER BY "Month";