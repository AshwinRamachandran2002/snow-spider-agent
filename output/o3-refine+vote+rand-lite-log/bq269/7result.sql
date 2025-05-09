WITH sessions AS (
  -- 1.  Sessions in scope, classified as purchase / non‑purchase
  SELECT
    PARSE_DATE('%Y%m%d', date)          AS session_date,
    fullVisitorId,
    totals.pageviews                    AS pageviews,
    CASE
      WHEN IFNULL(totals.transactions,0) > 0 THEN 'purchase'
      ELSE 'non_purchase'
    END                                 AS session_class
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'      -- 1 Jun – 31 Jul 2017
    AND totals.pageviews IS NOT NULL                         -- keep only sessions with page‑views
), visitor_monthly AS (
  -- 2.  Sum page‑views per visitor, per month, per class
  SELECT
    DATE_TRUNC(session_date, MONTH)    AS month,
    fullVisitorId,
    session_class,
    SUM(pageviews)                     AS visitor_pageviews
  FROM sessions
  GROUP BY month, fullVisitorId, session_class
)
-- 3.  Average page‑views per visitor in each class, by month
SELECT
  FORMAT_DATE('%Y-%m', month)                                   AS month,
  AVG(IF(session_class = 'purchase'     , visitor_pageviews, NULL)) AS avg_pageviews_purchase,
  AVG(IF(session_class = 'non_purchase' , visitor_pageviews, NULL)) AS avg_pageviews_non_purchase
FROM visitor_monthly
GROUP BY month
ORDER BY month;