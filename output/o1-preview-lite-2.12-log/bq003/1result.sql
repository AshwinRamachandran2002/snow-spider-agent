WITH sessions AS (
  SELECT
    fullVisitorId,
    FORMAT_DATE('%B-%Y', PARSE_DATE('%Y%m%d', date)) AS Month,
    totals.pageviews AS pageviews,
    CASE
      WHEN totals.transactions >= 1 AND 
           EXISTS (
             SELECT 1
             FROM UNNEST(hits) AS hit
             CROSS JOIN UNNEST(hit.product) AS product
             WHERE product.productRevenue IS NOT NULL
           ) THEN 'Purchase'
      WHEN totals.transactions IS NULL AND 
           NOT EXISTS (
             SELECT 1
             FROM UNNEST(hits) AS hit
             CROSS JOIN UNNEST(hit.product) AS product
             WHERE product.productRevenue IS NOT NULL
           ) THEN 'Non-Purchase'
      ELSE NULL
    END AS session_type
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170401' AND '20170731'
),
visitor_pageviews AS (
  SELECT
    Month,
    session_type,
    fullVisitorId,
    AVG(pageviews) AS avg_pageviews_per_visitor
  FROM sessions
  WHERE session_type IS NOT NULL
  GROUP BY Month, session_type, fullVisitorId
),
group_pageviews AS (
  SELECT
    Month,
    session_type,
    AVG(avg_pageviews_per_visitor) AS Average_Pageviews_Per_Visitor
  FROM visitor_pageviews
  GROUP BY Month, session_type
)
SELECT
  Month,
  session_type AS SessionType,
  ROUND(Average_Pageviews_Per_Visitor, 4) AS Average_Pageviews_Per_Visitor
FROM group_pageviews
ORDER BY PARSE_DATE('%B-%Y', Month), SessionType;