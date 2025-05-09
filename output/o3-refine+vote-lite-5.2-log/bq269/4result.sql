-- Average pageviews per visitor, split by purchase / non‑purchase sessions
WITH sessions AS (
  -- 1. keep only sessions in the required period that have pageviews
  SELECT
    SUBSTR(date,1,6)                       AS month,              -- 'YYYYMM'
    fullVisitorId,
    totals.pageviews                       AS pageviews,
    IFNULL(totals.transactions,0)          AS transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'
    AND totals.pageviews IS NOT NULL
),
classified AS (
  -- 2. classify every session
  SELECT
    month,
    fullVisitorId,
    CASE WHEN transactions > 0
         THEN 'purchase'
         ELSE 'non_purchase'
    END                                     AS classification,
    pageviews
  FROM sessions
),
visitor_totals AS (
  -- 3. sum pageviews per visitor & classification within each month
  SELECT
    month,
    fullVisitorId,
    classification,
    SUM(pageviews)                          AS visitor_pageviews
  FROM classified
  GROUP BY month, fullVisitorId, classification
)
-- 4. average pageviews per visitor for each class, show side‑by‑side
SELECT
  month,
  ROUND(AVG(IF(classification = 'purchase'     , visitor_pageviews, NULL)),4) AS purchase_avg_pageviews,
  ROUND(AVG(IF(classification = 'non_purchase' , visitor_pageviews, NULL)),4) AS non_purchase_avg_pageviews
FROM visitor_totals
GROUP BY month
ORDER BY month;