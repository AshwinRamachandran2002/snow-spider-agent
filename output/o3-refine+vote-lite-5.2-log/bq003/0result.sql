/*  Average pageviews per visitor for purchase vs. non‑purchase sessions
    April 1 – July 31  2017                                                */

WITH session_level AS (
  /* One row per session with a flag telling whether the session
     produced any product‑level revenue                                       */
  SELECT
    EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', date))           AS month,
    fullVisitorId,
    visitId,
    ANY_VALUE(totals.pageviews)                              AS pageviews,
    ANY_VALUE(totals.transactions)                           AS transactions,
    /* 1 if at least one product in the session has productRevenue */
    MAX( IF(p.productRevenue IS NOT NULL, 1, 0) )            AS has_product_revenue
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        UNNEST(hits)  AS h
        LEFT JOIN UNNEST(h.product) AS p
  WHERE LENGTH(_TABLE_SUFFIX)=8                             -- keep only daily tables
    AND _TABLE_SUFFIX BETWEEN '20170401' AND '20170731'     -- Apr 1 – Jul 31 2017
  GROUP BY  month, fullVisitorId, visitId
),

classified_sessions AS (
  /* keep only clearly purchase / non‑purchase sessions                       */
  SELECT
    month,
    fullVisitorId,
    pageviews,
    CASE
      WHEN transactions >= 1 AND has_product_revenue = 1
           THEN 'purchase'
      WHEN transactions IS NULL AND has_product_revenue = 0
           THEN 'non_purchase'
      ELSE NULL
    END AS session_type
  FROM session_level
  WHERE pageviews IS NOT NULL
),

visitor_month AS (
  /* aggregate pageviews at visitor‑month level within each session type      */
  SELECT
    month,
    session_type,
    fullVisitorId,
    SUM(pageviews) AS visitor_pageviews
  FROM classified_sessions
  WHERE session_type IS NOT NULL
  GROUP BY month, session_type, fullVisitorId
)

SELECT
  month,
  session_type,
  AVG(visitor_pageviews) AS avg_pageviews_per_visitor
FROM visitor_month
GROUP BY month, session_type
ORDER BY month, session_type;