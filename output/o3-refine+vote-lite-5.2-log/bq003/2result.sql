/*  Average pageviews per visitor (Purchase vs. Non‑purchase sessions)
    Period analysed : 2017‑04‑01  → 2017‑07‑31                                   */

WITH sessions AS (
  SELECT
      -- month in YYYY‑MM format
      FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', `date`))            AS month,
      fullVisitorId,
      IFNULL(totals.pageviews,0)                                     AS pageviews,

      -- fields used for purchase / non‑purchase classification
      totals.transactions                                            AS transactions,
      EXISTS (
          SELECT 1
          FROM UNNEST(hits) AS h
          CROSS JOIN UNNEST(h.product) AS p
          WHERE p.productRevenue IS NOT NULL
      )                                                              AS has_product_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170401' AND '20170731'              -- Apr 1 – Jul 31 2017
),

classified AS (
  SELECT
      month,
      fullVisitorId,
      pageviews,
      CASE
          WHEN transactions >= 1 AND has_product_revenue         THEN 'Purchase'
          WHEN transactions IS NULL AND NOT has_product_revenue  THEN 'Non-Purchase'
      END                                                         AS session_type
  FROM sessions
  WHERE (transactions >= 1 AND has_product_revenue)               -- strictly keep
     OR (transactions IS NULL AND NOT has_product_revenue)        --   classified rows
),

visitor_monthly_totals AS (
  /* pageviews aggregated per visitor, per month, per session type */
  SELECT
      month,
      session_type,
      fullVisitorId,
      SUM(pageviews) AS visitor_pageviews
  FROM classified
  GROUP BY
      month, session_type, fullVisitorId
)

SELECT
    month,
    session_type,
    ROUND(AVG(visitor_pageviews), 4) AS avg_pageviews_per_visitor
FROM visitor_monthly_totals
GROUP BY
    month, session_type
ORDER BY
    month,
    session_type;