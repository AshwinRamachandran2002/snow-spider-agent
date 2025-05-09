-- Average pageviews per visitor for purchase vs. non‑purchase sessions  
-- (only sessions having pageviews) during Jun‑Jul 2017
WITH sessions AS (
  SELECT
    _TABLE_SUFFIX                      AS session_date,
    SUBSTR(_TABLE_SUFFIX,1,6)          AS month,          -- 'YYYYMM'
    fullVisitorId                      AS visitor_id,
    SAFE_CAST(totals.pageviews AS INT64)      AS pageviews,
    IFNULL(totals.transactions,0)      AS transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'
    AND totals.pageviews IS NOT NULL                 -- keep sessions that have pageviews
),

classified AS (
  SELECT
    month,
    visitor_id,
    CASE WHEN transactions > 0 THEN 'purchase' ELSE 'non_purchase' END AS purchase_flag,
    pageviews
  FROM sessions
),

-- sum pageviews for each visitor within each month & classification
visitor_monthly AS (
  SELECT
    month,
    visitor_id,
    purchase_flag,
    SUM(pageviews) AS visitor_pageviews
  FROM classified
  GROUP BY month, visitor_id, purchase_flag
),

-- average those per‑visitor sums for each class & month
avg_pageviews AS (
  SELECT
    month,
    purchase_flag,
    AVG(visitor_pageviews) AS avg_pageviews_per_visitor
  FROM visitor_monthly
  GROUP BY month, purchase_flag
)

-- present results side‑by‑side
SELECT
  month,
  MAX(CASE WHEN purchase_flag = 'purchase'     THEN avg_pageviews_per_visitor END) AS purchase_avg_pageviews,
  MAX(CASE WHEN purchase_flag = 'non_purchase' THEN avg_pageviews_per_visitor END) AS non_purchase_avg_pageviews
FROM avg_pageviews
GROUP BY month
ORDER BY month;