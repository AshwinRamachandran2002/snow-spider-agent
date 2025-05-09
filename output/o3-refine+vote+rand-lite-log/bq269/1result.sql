/* Average pageviews per visitor for purchase vs. non‑purchase sessions,
   June – July 2017                                                  */

WITH sessions_filtered AS (
  SELECT
    SUBSTR(date,1,6)                         AS month ,          -- e.g. 201706
    fullVisitorId                            AS visitor ,
    CASE
      WHEN SAFE_CAST(totals.transactions AS INT64) > 0
           THEN 'purchase'
      ELSE 'non_purchase'
    END                                       AS session_type ,
    SAFE_CAST(totals.pageviews AS INT64)      AS pageviews
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'           -- 1 Jun – 31 Jul 2017
    AND totals.pageviews IS NOT NULL                              -- keep only sessions having pageviews
),

/* Sum pageviews per visitor, month and session classification */
visitor_monthly AS (
  SELECT
    month ,
    visitor ,
    session_type ,
    SUM(pageviews) AS visitor_pageviews
  FROM sessions_filtered
  GROUP BY month, visitor, session_type
),

/* Average those visitor‑level sums inside each month & class */
avg_pageviews AS (
  SELECT
    month ,
    session_type ,
    ROUND(AVG(visitor_pageviews),4) AS avg_pageviews_per_visitor
  FROM visitor_monthly
  GROUP BY month, session_type
)

/* Pivot purchase / non‑purchase averages side by side */
SELECT
  month ,
  MAX(CASE WHEN session_type = 'purchase'     THEN avg_pageviews_per_visitor END) AS purchase_avg_pageviews ,
  MAX(CASE WHEN session_type = 'non_purchase' THEN avg_pageviews_per_visitor END) AS non_purchase_avg_pageviews
FROM avg_pageviews
GROUP BY month
ORDER BY month;