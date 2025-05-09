-- Average pageviews per visitor, split by purchase vs non-purchase sessions
-- for each month from April 01 – July 31 2017
WITH sessions AS (
  SELECT
    SUBSTR(_TABLE_SUFFIX, 1, 6)                               AS month_yyyymm,
    fullVisitorId,
    totals.pageviews                                          AS pageviews,
    CASE
      WHEN totals.transactions >= 1
           AND EXISTS (
                 SELECT 1
                 FROM UNNEST(hits) h
                 JOIN UNNEST(h.product) p ON TRUE
                 WHERE p.productRevenue IS NOT NULL
               )
      THEN 'purchase'
      ELSE 'non_purchase'
    END                                                       AS session_type
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170401' AND '20170731'
),
visitor_month AS (
  SELECT
    month_yyyymm,
    fullVisitorId,
    SUM(pageviews)                                            AS visitor_pageviews,
    CASE
      WHEN MAX(session_type = 'purchase') = TRUE
      THEN 'purchase'
      ELSE 'non_purchase'
    END                                                       AS visitor_group
  FROM sessions
  GROUP BY month_yyyymm, fullVisitorId
)
SELECT
  FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m', month_yyyymm))      AS month,
  visitor_group                                               AS session_type,
  AVG(visitor_pageviews)                                      AS avg_pageviews_per_visitor
FROM visitor_month
GROUP BY month_yyyymm, visitor_group
ORDER BY month, session_type;