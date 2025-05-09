/*  Average page-views per visitor for purchase vs. non-purchase groups
    – April 1 to July 31 2017                                      */

WITH session_level AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', _TABLE_SUFFIX))        AS month,
    `fullVisitorId`,
    IFNULL(`totals`.pageviews, 0)                                    AS pageviews,
    -- flag this session as “purchase” only if it has ≥1 transaction
    -- AND at least one non-null productRevenue value
    CASE
      WHEN `totals`.transactions >= 1
           AND EXISTS (
                 SELECT 1
                 FROM UNNEST(`hits`)     AS h
                 CROSS JOIN UNNEST(h.product) AS p
                 WHERE p.productRevenue IS NOT NULL )
      THEN 1 ELSE 0
    END                                                              AS purchase_session_flag
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170401' AND '20170731'
),

visitor_level AS (
  /* aggregate to visitor-month level */
  SELECT
    month,
    `fullVisitorId`,
    SUM(pageviews)                              AS visitor_pageviews,
    MAX(purchase_session_flag)                  AS purchase_flag        -- 1 if the visitor had any purchase session
  FROM session_level
  GROUP BY month, `fullVisitorId`
)

SELECT
  month,
  CASE WHEN purchase_flag = 1 THEN 'purchase' ELSE 'non_purchase' END AS visitor_type,
  AVG(visitor_pageviews)                                              AS avg_pageviews_per_visitor
FROM visitor_level
GROUP BY month, visitor_type
ORDER BY month, visitor_type;