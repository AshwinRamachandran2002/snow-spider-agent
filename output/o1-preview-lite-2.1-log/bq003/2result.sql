WITH sessions AS (
  SELECT
    FORMAT_DATE('%b-%Y', PARSE_DATE('%Y%m%d', date)) AS Month,
    fullVisitorId,
    totals.pageviews AS pageviews,
    CASE
      WHEN totals.transactions > 0 THEN 'Purchase'
      ELSE 'NonPurchase'
    END AS session_type
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20170401' AND '20170731'
    AND totals.pageviews IS NOT NULL
    AND fullVisitorId IS NOT NULL
),
visitor_pageviews AS (
  SELECT
    Month,
    session_type,
    fullVisitorId,
    SUM(pageviews) AS total_pageviews_per_visitor
  FROM
    sessions
  GROUP BY
    Month, session_type, fullVisitorId
)
SELECT
  Month,
  ROUND(AVG(IF(session_type = 'Purchase', total_pageviews_per_visitor, NULL)), 4) AS Average_Pageviews_per_Visitor_Purchase_Sessions,
  ROUND(AVG(IF(session_type = 'NonPurchase', total_pageviews_per_visitor, NULL)), 4) AS Average_Pageviews_per_Visitor_NonPurchase_Sessions
FROM
  visitor_pageviews
GROUP BY
  Month
ORDER BY
  PARSE_DATE('%b-%Y', Month);