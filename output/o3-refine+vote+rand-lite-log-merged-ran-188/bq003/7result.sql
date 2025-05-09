-- Average pageviews per visitor for purchase vs. non‑purchase sessions
-- (purchase: transactions ≥1 AND some productRevenue present;
--  non‑purchase: transactions IS NULL AND no productRevenue)

WITH session_level AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date))               AS month,
    fullVisitorId,
    IFNULL(totals.pageviews, 0)                                    AS pageviews,
    CASE
      WHEN totals.transactions >= 1
           AND EXISTS (SELECT 1
                       FROM UNNEST(hits) h
                       JOIN UNNEST(h.product) p
                       WHERE p.productRevenue IS NOT NULL)
        THEN 'purchase'
      WHEN totals.transactions IS NULL
           AND NOT EXISTS (SELECT 1
                           FROM UNNEST(hits) h
                           JOIN UNNEST(h.product) p
                           WHERE p.productRevenue IS NOT NULL)
        THEN 'non_purchase'
      ELSE NULL                       -- sessions that don’t cleanly fit either group
    END AS session_type
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170401' AND '20170731'            -- Apr 1 – Jul 31 2017
),
visitor_level AS (
  SELECT
    month,
    session_type,
    fullVisitorId,
    SUM(pageviews) AS pageviews_per_visitor                        -- combine multiple sessions of same type
  FROM session_level
  WHERE session_type IS NOT NULL                                   -- keep only classified sessions
  GROUP BY month, session_type, fullVisitorId
)
SELECT
  month,
  session_type,
  ROUND(AVG(pageviews_per_visitor), 4) AS avg_pageviews_per_visitor
FROM visitor_level
GROUP BY month, session_type
ORDER BY month, session_type;