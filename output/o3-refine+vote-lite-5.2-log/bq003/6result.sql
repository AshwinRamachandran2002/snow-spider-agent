/*  Average pageviews per visitor for purchase vs. non‑purchase sessions
    April 1 – July 31 2017                                          */

WITH sessions AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)) AS month,
    fullVisitorId,
    IFNULL(totals.pageviews, 0)                               AS pageviews,
    totals.transactions                                       AS transactions,
    -- number of products inside the session that have a productRevenue value
    (
      SELECT COUNTIF(p.productRevenue IS NOT NULL)
      FROM UNNEST(hits) AS h
      CROSS JOIN UNNEST(h.product) AS p
    )                                                        AS product_rev_cnt
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170401' AND '20170731'
),

classified AS (
  SELECT
    month,
    fullVisitorId,
    pageviews,
    CASE
      WHEN transactions >= 1 AND product_rev_cnt > 0 THEN 'purchase'
      WHEN transactions IS NULL AND product_rev_cnt = 0 THEN 'non_purchase'
      ELSE NULL                        -- exclude ambiguous sessions
    END AS session_type
  FROM sessions
)

SELECT
  month,
  session_type,
  SUM(pageviews)                            AS total_pageviews,
  COUNT(DISTINCT fullVisitorId)             AS visitors,
  SAFE_DIVIDE(SUM(pageviews),
              COUNT(DISTINCT fullVisitorId)) AS avg_pageviews_per_visitor
FROM classified
WHERE session_type IS NOT NULL
GROUP BY month, session_type
ORDER BY month, session_type;