/*  Average pageviews per visitor for purchase vs. non‑purchase sessions,
    April‑July 2017                                                 */

WITH sessions AS (
  SELECT
    SUBSTR(date,1,6)                       AS month,          -- e.g. 201704
    fullVisitorId,
    IFNULL(totals.pageviews,0)             AS pageviews,
    totals.transactions                    AS transactions,

    /* did the session contain at least one product with revenue? */
    EXISTS (
      SELECT 1
      FROM UNNEST(hits)    AS h
      CROSS JOIN UNNEST(h.product) AS p
      WHERE p.productRevenue IS NOT NULL
    )                                       AS has_product_revenue
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170401' AND '20170731'        -- Apr 1 – Jul 31 2017
),

classified AS (
  SELECT
    month,
    fullVisitorId,
    pageviews,
    CASE
      WHEN transactions >= 1
           AND has_product_revenue            THEN 'purchase'
      WHEN transactions IS NULL
           AND NOT has_product_revenue        THEN 'non_purchase'
      -- other combinations are discarded
    END                                        AS session_type
  FROM sessions
  WHERE (transactions >= 1  AND has_product_revenue)
     OR (transactions IS NULL AND NOT has_product_revenue)
),

visitor_month AS (
  /* pageviews aggregated per visitor, month, and session‑type */
  SELECT
    month,
    session_type,
    fullVisitorId,
    SUM(pageviews)  AS pageviews_per_visitor
  FROM classified
  GROUP BY month, session_type, fullVisitorId
)

SELECT
  month,
  session_type,
  ROUND(AVG(pageviews_per_visitor),4) AS avg_pageviews_per_visitor
FROM visitor_month
GROUP BY month, session_type
ORDER BY month, session_type;