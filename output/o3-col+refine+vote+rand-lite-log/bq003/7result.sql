/*  Average pageviews per visitor
    ─────────────────────────────
    • Scope : Apr-01-2017  →  Jul-31-2017
    • Groups: ‘Purchase’       = transactions ≥ 1  AND productRevenue NOT NULL
              ‘Non-Purchase’   = transactions IS NULL AND productRevenue IS NULL
    • Steps :
        1. Pull sessions in date-range and compute session-level product revenue.
        2. Label each session as Purchase / Non-Purchase (ignore others).
        3. Sum pageviews per visitor-month inside each group.
        4. Average those visitor totals for every month & group.
*/
WITH sessions AS (            -- step 1
  SELECT
    DATE_TRUNC(PARSE_DATE('%Y%m%d', date), MONTH)        AS month,
    fullVisitorId,
    totals.pageviews                                       AS pageviews,
    totals.transactions                                    AS transactions,
    ( SELECT SUM(p.productRevenue)
      FROM UNNEST(hits) h, UNNEST(h.product) p )           AS session_product_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  WHERE _TABLE_SUFFIX BETWEEN '0401' AND '0731'            -- Apr-01 → Jul-31
),
classified AS (         -- step 2
  SELECT
    month,
    fullVisitorId,
    pageviews,
    CASE
      WHEN transactions >= 1
           AND session_product_revenue IS NOT NULL THEN 'Purchase'
      WHEN transactions IS NULL
           AND session_product_revenue IS NULL THEN 'Non-Purchase'
    END AS session_type
  FROM sessions
),
visitor_month AS (      -- step 3
  SELECT
    month,
    session_type,
    fullVisitorId,
    SUM(pageviews) AS pageviews_per_visitor
  FROM classified
  WHERE session_type IS NOT NULL               -- keep only the two groups of interest
  GROUP BY month, session_type, fullVisitorId
)
-- step 4  – average per month & group
SELECT
  month,
  session_type,
  ROUND(AVG(pageviews_per_visitor), 4) AS avg_pageviews_per_visitor
FROM visitor_month
GROUP BY month, session_type
ORDER BY month, session_type;