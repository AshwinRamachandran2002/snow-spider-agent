WITH sessions AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date)) AS month,
    fullVisitorId,
    CASE
      WHEN totals.transactions >= 1
           AND EXISTS (
             SELECT 1
             FROM UNNEST(hits) h, UNNEST(h.product) p
             WHERE p.productRevenue IS NOT NULL
           )
        THEN 'purchase'
      WHEN totals.transactions IS NULL
           AND NOT EXISTS (
             SELECT 1
             FROM UNNEST(hits) h, UNNEST(h.product) p
             WHERE p.productRevenue IS NOT NULL
           )
        THEN 'non-purchase'
      ELSE NULL
    END AS session_type,
    COALESCE(totals.pageviews, 0) AS pageviews
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  WHERE date BETWEEN '20170401' AND '20170731'
),
visitor_month AS (
  SELECT
    month,
    fullVisitorId,
    session_type,
    SUM(pageviews) AS pageviews_per_visitor
  FROM sessions
  WHERE session_type IS NOT NULL
  GROUP BY month, fullVisitorId, session_type
)
SELECT
  month,
  session_type AS `group`,
  ROUND(AVG(pageviews_per_visitor), 4) AS avg_pageviews
FROM visitor_month
GROUP BY month, `group`
ORDER BY month, `group`;