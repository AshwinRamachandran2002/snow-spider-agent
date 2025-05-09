/*  Average page‑views per visitor by month (Apr‑Jul 2017)
    separated into purchase vs. non‑purchase sessions          */

WITH sessions AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', `date`))      AS month,        -- yyyy-mm
    fullVisitorId,
    totals.pageviews                                        AS pageviews,    -- per‑session views
    totals.transactions                                     AS transactions,
    /* total product revenue inside the session               */
    ( SELECT SUM(p.productRevenue)
        FROM UNNEST(hits) h,
             UNNEST(h.product) p )                          AS product_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170401' AND '20170731'     -- Apr 1 – Jul 31 2017
),

/* classify each session */
classified AS (
  SELECT
    month,
    fullVisitorId,
    pageviews,
    CASE
      WHEN transactions >= 1 AND product_revenue IS NOT NULL THEN 'purchase'
      WHEN transactions IS NULL  AND product_revenue IS NULL THEN 'non_purchase'
    END                                                    AS session_type
  FROM sessions
  WHERE (transactions >= 1 AND product_revenue IS NOT NULL)   -- keep only
     OR (transactions IS NULL  AND product_revenue IS NULL)   -- the two groups
),

/* roll up to visitor‑month level */
visitor_month AS (
  SELECT
    month,
    fullVisitorId,
    session_type,
    SUM(pageviews) AS total_pageviews                       -- all sessions of that type
  FROM classified
  GROUP BY month, fullVisitorId, session_type
)

/* final comparison */
SELECT
  month,
  session_type,
  AVG(total_pageviews) AS avg_pageviews_per_visitor
FROM visitor_month
GROUP BY month, session_type
ORDER BY month, session_type;