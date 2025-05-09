WITH sessions AS (
  SELECT
    _TABLE_SUFFIX AS dt,
    fullVisitorId,
    CASE WHEN totals.transactions >= 1 THEN 'purchase' ELSE 'non_purchase' END AS class,
    totals.pageviews AS pageviews
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'
    AND totals.pageviews IS NOT NULL
),
per_visitor_month AS (
  SELECT
    FORMAT_DATE('%Y-%m', DATE(PARSE_DATE('%Y%m%d', dt))) AS month,
    fullVisitorId,
    class,
    SUM(pageviews) AS pageviews_per_visitor
  FROM sessions
  GROUP BY month, fullVisitorId, class
),
avg_pageviews AS (
  SELECT
    month,
    class,
    ROUND(AVG(pageviews_per_visitor), 4) AS avg_pv
  FROM per_visitor_month
  GROUP BY month, class
)
SELECT
  month,
  MAX(IF(class = 'purchase',     avg_pv, NULL)) AS avg_pageviews_purchase,
  MAX(IF(class = 'non_purchase', avg_pv, NULL)) AS avg_pageviews_non_purchase
FROM avg_pageviews
GROUP BY month
ORDER BY month;