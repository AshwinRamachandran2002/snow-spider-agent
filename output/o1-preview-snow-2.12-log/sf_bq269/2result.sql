WITH sessions AS (
  SELECT "date", "fullVisitorId",
    ("totals":"pageviews")::NUMBER AS pageviews,
    ("totals":"transactions")::NUMBER AS transactions,
    CASE WHEN ("totals":"transactions")::NUMBER >= 1 THEN 'purchase' ELSE 'non_purchase' END AS classification,
    SUBSTR("date", 1, 6) AS "month"
  FROM (
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170601"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170602"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170604"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170606"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170609"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170610"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170611"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170613"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170614"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170615"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170616"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170617"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170618"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170619"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170620"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170621"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170622"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170623"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170624"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170625"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170626"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170627"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170628"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170629"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170701"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170702"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170703"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170704"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170705"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170707"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170709"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170710"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170711"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170713"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170715"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170716"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170717"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170718"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170720"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170721"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170722"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170723"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170724"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170726"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170727"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170728"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170729"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170730"
    UNION ALL
    SELECT "date", "fullVisitorId", "totals"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170731"
  )
)
SELECT
  CASE WHEN "month" = '201706' THEN 'June 2017' ELSE 'July 2017' END AS "Month",
  ROUND(AVG(CASE WHEN classification = 'purchase' THEN total_pageviews END), 6) AS "Average_Pageviews_Purchase",
  ROUND(AVG(CASE WHEN classification = 'non_purchase' THEN total_pageviews END), 6) AS "Average_Pageviews_Non_Purchase"
FROM (
  SELECT "month", "fullVisitorId", classification, SUM(pageviews) AS total_pageviews
  FROM sessions
  WHERE pageviews IS NOT NULL
  GROUP BY "month", "fullVisitorId", classification
) t
GROUP BY "month"
ORDER BY "Month";